use cloud_core::diff;
use ratatui::{
    layout::Rect,
    style::{Color, Style},
    text::{Line, Span},
    widgets::{Block, Borders, Paragraph, Wrap},
    Frame,
};

pub fn render_plan(f: &mut Frame, area: Rect, plan: &Option<serde_json::Value>) {
    let Some(plan) = plan else {
        f.render_widget(
            Paragraph::new("No plan yet. Press `p` to run terraform plan + show -json.")
                .block(Block::default().borders(Borders::ALL).title("plan")),
            area,
        );
        return;
    };
    let (add, chg, del) = diff::plan_summary(plan);
    let mut lines = vec![Line::from(vec![
        Span::styled(format!("+{add} "), Style::default().fg(Color::Green)),
        Span::styled(format!("~{chg} "), Style::default().fg(Color::Yellow)),
        Span::styled(format!("-{del}"), Style::default().fg(Color::Red)),
    ])];
    if let Some(rc) = plan.get("resource_changes").and_then(|v| v.as_array()) {
        for r in rc.iter().take(40) {
            let addr = r.get("address").and_then(|v| v.as_str()).unwrap_or("?");
            let acts = r
                .get("change")
                .and_then(|c| c.get("actions"))
                .map(|v| v.to_string())
                .unwrap_or_default();
            let (sym, col) = if acts.contains("create") && !acts.contains("delete") {
                ("+", Color::Green)
            } else if acts.contains("delete") && !acts.contains("create") {
                ("-", Color::Red)
            } else if acts.contains("no-op") || acts.contains("read") {
                (" ", Color::DarkGray)
            } else {
                ("~", Color::Yellow)
            };
            lines.push(Line::from(vec![
                Span::styled(format!("{sym} "), Style::default().fg(col)),
                Span::raw(format!("{addr} {acts}")),
            ]));
        }
        if rc.len() > 40 {
            lines.push(Line::from(format!("… {} more", rc.len() - 40)));
        }
    }
    f.render_widget(
        Paragraph::new(lines)
            .block(Block::default().borders(Borders::ALL).title("plan diff"))
            .wrap(Wrap { trim: false }),
        area,
    );
}

pub fn render_outputs(f: &mut Frame, area: Rect, outputs: &Option<serde_json::Value>) {
    let Some(outputs) = outputs else {
        f.render_widget(
            Paragraph::new("No outputs yet. Press `o`.")
                .block(Block::default().borders(Borders::ALL).title("outputs")),
            area,
        );
        return;
    };
    let txt = serde_json::to_string_pretty(outputs).unwrap_or_default();
    let short: String = txt.chars().take(6000).collect();
    f.render_widget(
        Paragraph::new(short)
            .block(
                Block::default()
                    .borders(Borders::ALL)
                    .title("outputs (json)"),
            )
            .wrap(Wrap { trim: false }),
        area,
    );
}
