use anyhow::Result;
use cloud_core::{checks, checks::StackCheck, discover_profiles, ProviderProfile, TerraformRunner};
use crossterm::{
    event::{self, DisableMouseCapture, EnableMouseCapture, Event, KeyCode},
    execute,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
};
use ratatui::{
    backend::CrosstermBackend,
    layout::{Constraint, Direction, Layout},
    style::{Color, Style},
    text::{Line, Span},
    widgets::{Block, Borders, ListState, Paragraph, Wrap},
    Terminal,
};
use std::io;
use std::path::PathBuf;
use std::time::Duration;
use tokio::sync::mpsc;

enum JobMsg {
    Log(String),
    PlanDone(serde_json::Value, String),
    OutputsDone(serde_json::Value),
    SimpleDone(String),
    Err(String),
}

struct App {
    profiles: Vec<ProviderProfile>,
    list_state: ListState,
    tab: usize,
    logs: Vec<String>,
    status: String,
    plan: Option<serde_json::Value>,
    plan_raw: String,
    outputs: Option<serde_json::Value>,
    check_results: Vec<StackCheck>,
    busy: bool,
}

impl App {
    fn selected(&self) -> Option<&ProviderProfile> {
        self.list_state
            .selected()
            .and_then(|i| self.profiles.get(i))
    }
    fn push_log(&mut self, s: String) {
        self.logs.push(s);
        if self.logs.len() > 500 {
            let n = self.logs.len() - 500;
            self.logs.drain(..n);
        }
    }
}

fn root() -> PathBuf {
    std::env::current_dir()
        .unwrap_or(PathBuf::from("."))
        .join("..")
        .canonicalize()
        .unwrap_or(PathBuf::from(".."))
}

fn spawn_job<F>(tx: mpsc::UnboundedSender<JobMsg>, fut: F)
where
    F: std::future::Future<Output = ()> + Send + 'static,
{
    tokio::spawn(fut);
    let _ = tx;
}

pub async fn run() -> Result<()> {
    let profiles = discover_profiles(&root());
    if profiles.is_empty() {
        anyhow::bail!("no terraform-* stacks found under {}", root().display());
    }
    let mut app = App {
        profiles,
        list_state: {
            let mut s = ListState::default();
            s.select(Some(0));
            s
        },
        tab: 0,
        logs: vec!["q=quit tab=switch p=plan o=outputs c=checks i=init v=validate f=fmt".into()],
        status: "ready".into(),
        plan: None,
        plan_raw: String::new(),
        outputs: None,
        check_results: vec![],
        busy: false,
    };

    enable_raw_mode()?;
    let mut stdout = io::stdout();
    execute!(stdout, EnterAlternateScreen, EnableMouseCapture)?;
    let backend = CrosstermBackend::new(stdout);
    let mut terminal = Terminal::new(backend)?;
    let (tx, mut rx) = mpsc::unbounded_channel::<JobMsg>();

    loop {
        // drain jobs
        while let Ok(msg) = rx.try_recv() {
            match msg {
                JobMsg::Log(l) => app.push_log(l),
                JobMsg::SimpleDone(s) => {
                    app.busy = false;
                    app.status = s.clone();
                    app.push_log(s);
                }
                JobMsg::Err(e) => {
                    app.busy = false;
                    app.status = format!("error: {}", short(&e));
                    app.push_log(format!("ERROR: {e}"));
                }
                JobMsg::PlanDone(v, raw) => {
                    app.busy = false;
                    app.plan = Some(v);
                    app.plan_raw = raw.clone();
                    app.status = "plan ok".into();
                    app.push_log(raw);
                    app.tab = 1;
                }
                JobMsg::OutputsDone(v) => {
                    app.busy = false;
                    app.outputs = Some(v);
                    app.status = "outputs ok".into();
                    app.tab = 2;
                }
            }
        }

        terminal.draw(|f| {
            let chunks = Layout::default()
                .direction(Direction::Vertical)
                .constraints([
                    Constraint::Length(3),
                    Constraint::Min(5),
                    Constraint::Length(3),
                ])
                .split(f.size());
            let tabs = ["1:Detail", "2:Plan", "3:Outputs", "4:Checks", "5:Logs"];
            let header = Paragraph::new(Line::from(vec![
                Span::styled(
                    "terraform-cloud  ",
                    Style::default().fg(Color::Cyan),
                ),
                Span::raw(tabs.join("  ")),
                Span::raw(format!("   | {} | {}", app.status, if app.busy { "BUSY" } else { "idle" })),
            ]))
            .block(Block::default().borders(Borders::ALL));
            f.render_widget(header, chunks[0]);

            let body = Layout::default()
                .direction(Direction::Horizontal)
                .constraints([Constraint::Percentage(32), Constraint::Percentage(68)])
                .split(chunks[1]);
            crate::widgets::render_providers(f, body[0], &app.profiles, &mut app.list_state.clone());

            match app.tab {
                0 => render_detail(f, body[1], &app),
                1 => crate::widgets::render_plan(f, body[1], &app.plan),
                2 => crate::widgets::render_outputs(f, body[1], &app.outputs),
                3 => crate::widgets::render_checks(f, body[1], &app.check_results),
                _ => {
                    let txt = app.logs.join("\n");
                    let short: String = txt.chars().rev().take(4000).collect::<String>().chars().rev().collect();
                    f.render_widget(
                        Paragraph::new(short)
                            .block(Block::default().borders(Borders::ALL).title("logs"))
                            .wrap(Wrap { trim: false }),
                        body[1],
                    );
                }
            }

            f.render_widget(
                Paragraph::new("j/k move  tab switch  p plan  o outputs  c checks  i init  v validate  f fmt  q quit")
                    .block(Block::default().borders(Borders::ALL)),
                chunks[2],
            );
        })?;

        if event::poll(Duration::from_millis(120))? {
            if let Event::Key(k) = event::read()? {
                match k.code {
                    KeyCode::Char('q') | KeyCode::Esc => break,
                    KeyCode::Down | KeyCode::Char('j') => {
                        let n = app.profiles.len();
                        let cur = app.list_state.selected().unwrap_or(0);
                        app.list_state.select(Some((cur + 1) % n));
                    }
                    KeyCode::Up | KeyCode::Char('k') => {
                        let n = app.profiles.len();
                        let cur = app.list_state.selected().unwrap_or(0);
                        app.list_state.select(Some((cur + n - 1) % n));
                    }
                    KeyCode::Tab => app.tab = (app.tab + 1) % 5,
                    KeyCode::Char('1') => app.tab = 0,
                    KeyCode::Char('2') => app.tab = 1,
                    KeyCode::Char('3') => app.tab = 2,
                    KeyCode::Char('4') => app.tab = 3,
                    KeyCode::Char('5') => app.tab = 4,
                    KeyCode::Char('c') => {
                        if let Some(p) = app.selected().cloned() {
                            app.check_results = checks::all_checks(&p.dir);
                            app.status = format!("checks: {}", p.id);
                            app.push_log(format!(
                                "checks {}: {} items",
                                p.id,
                                app.check_results.len()
                            ));
                            app.tab = 3;
                        }
                    }
                    KeyCode::Char('i') => run_simple(&mut app, &tx, &["init"]),
                    KeyCode::Char('v') => run_simple(&mut app, &tx, &["validate"]),
                    KeyCode::Char('f') => run_simple(&mut app, &tx, &["fmt"]),
                    KeyCode::Char('o') => {
                        if app.busy {
                            continue;
                        }
                        if let Some(p) = app.selected().cloned() {
                            app.busy = true;
                            app.status = format!("outputs {}", p.id);
                            let tx2 = tx.clone();
                            spawn_job(tx.clone(), async move {
                                let r = TerraformRunner::new(p.dir);
                                match r.output_json().await {
                                    Ok(v) => {
                                        let _ = tx2.send(JobMsg::OutputsDone(v));
                                    }
                                    Err(e) => {
                                        let _ = tx2.send(JobMsg::Err(e.to_string()));
                                    }
                                }
                            });
                        }
                    }
                    KeyCode::Char('p') => {
                        if app.busy {
                            continue;
                        }
                        if let Some(p) = app.selected().cloned() {
                            app.busy = true;
                            app.status = format!("plan {}", p.id);
                            app.push_log(format!("plan {} …", p.id));
                            let tx2 = tx.clone();
                            spawn_job(tx.clone(), async move {
                                let r = TerraformRunner::new(p.dir);
                                let _ = tx2.send(JobMsg::Log("terraform plan…".into()));
                                match r.plan().await {
                                    Ok(raw) => match r.show_json().await {
                                        Ok(v) => {
                                            let _ = tx2.send(JobMsg::PlanDone(v, raw));
                                        }
                                        Err(e) => {
                                            let _ = tx2.send(JobMsg::Err(format!("show: {e}")));
                                        }
                                    },
                                    Err(e) => {
                                        let _ = tx2.send(JobMsg::Err(e.to_string()));
                                    }
                                }
                            });
                        }
                    }
                    _ => {}
                }
            }
        }
    }

    disable_raw_mode()?;
    execute!(
        terminal.backend_mut(),
        LeaveAlternateScreen,
        DisableMouseCapture
    )?;
    terminal.show_cursor()?;
    Ok(())
}

fn short(s: &str) -> String {
    s.chars().take(160).collect()
}

fn run_simple(app: &mut App, tx: &mpsc::UnboundedSender<JobMsg>, args: &[&str]) {
    if app.busy {
        return;
    }
    let Some(p) = app.selected().cloned() else {
        return;
    };
    let a: Vec<String> = args.iter().map(|s| s.to_string()).collect();
    app.busy = true;
    app.status = format!("{} {}", a.join(" "), p.id);
    let tx2 = tx.clone();
    tokio::spawn(async move {
        let r = TerraformRunner::new(p.dir.clone());
        let res = match a[0].as_str() {
            "init" => r.init().await,
            "validate" => r.validate().await,
            "fmt" => r.fmt_check().await,
            _ => Ok("ok".into()),
        };
        match res {
            Ok(o) => {
                let _ = tx2.send(JobMsg::SimpleDone(format!("{} ok: {}", a[0], short(&o))));
            }
            Err(e) => {
                let _ = tx2.send(JobMsg::Err(e.to_string()));
            }
        }
    });
}

fn render_detail(f: &mut ratatui::Frame, area: ratatui::layout::Rect, app: &App) {
    let Some(p) = app.selected() else { return };
    let txt = format!(
        "id: {}\ndir: {}\nkind: {:?}\ntf files: {}\nvars({}): {}\nresources({}): {}\nproviders: {}\ntfvars: {}  state: {}",
        p.id,
        p.dir.display(),
        p.kind,
        p.tf_file_count,
        p.var_names.len(),
        p.var_names.iter().take(12).cloned().collect::<Vec<_>>().join(","),
        p.resource_types.len(),
        p.resource_types.iter().take(8).cloned().collect::<Vec<_>>().join(","),
        if p.provider_sources.is_empty() { "(none detected)".into() } else { p.provider_sources.join(",") },
        p.has_tfvars,
        p.has_state,
    );
    f.render_widget(
        Paragraph::new(txt)
            .block(Block::default().borders(Borders::ALL).title("stack detail"))
            .wrap(Wrap { trim: false }),
        area,
    );
}
