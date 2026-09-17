use cloud_core::checks::{Level, StackCheck};
use ratatui::{
    layout::Rect,
    style::{Color, Style},
    text::Line,
    widgets::{Block, Borders, Paragraph, Wrap},
    Frame,
};

pub fn render_checks(f: &mut Frame, area: Rect, checks: &[StackCheck]) {
    if checks.is_empty() {
        f.render_widget(
            Paragraph::new("No checks yet. Press `c`.")
                .block(Block::default().borders(Borders::ALL).title("checks")),
            area,
        );
        return;
    }
    let lines: Vec<Line> = checks
        .iter()
        .map(|c| {
            let (tag, col) = match c.level {
                Level::Pass => ("PASS", Color::Green),
                Level::Warn => ("WARN", Color::Yellow),
                Level::Fail => ("FAIL", Color::Red),
            };
            Line::from(vec![
                ratatui::text::Span::styled(format!("[{tag}] "), Style::default().fg(col)),
                ratatui::text::Span::raw(format!("{} — {}", c.name, c.detail)),
            ])
        })
        .collect();
    f.render_widget(
        Paragraph::new(lines)
            .block(Block::default().borders(Borders::ALL).title("checks"))
            .wrap(Wrap { trim: false }),
        area,
    );
}
