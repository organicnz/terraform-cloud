use cloud_core::ProviderProfile;
use ratatui::{
    layout::Rect,
    style::{Color, Modifier, Style},
    widgets::{Block, Borders, List, ListItem, ListState},
    Frame,
};

pub fn render_providers(
    f: &mut Frame,
    area: Rect,
    profiles: &[ProviderProfile],
    state: &mut ListState,
) {
    let items: Vec<ListItem> = profiles
        .iter()
        .map(|p| {
            let kind = match p.kind {
                cloud_core::StackKind::Vps => "vps",
                cloud_core::StackKind::Dns => "dns",
                cloud_core::StackKind::Unknown => "?",
            };
            let flag = if p.has_state { "*" } else { " " };
            ListItem::new(format!(
                "{}[{}] {} (tf:{})",
                flag, kind, p.id, p.tf_file_count
            ))
        })
        .collect();
    let list = List::new(items)
        .block(Block::default().borders(Borders::ALL).title("providers"))
        .highlight_style(
            Style::default()
                .bg(Color::Blue)
                .add_modifier(Modifier::BOLD),
        )
        .highlight_symbol("> ");
    f.render_stateful_widget(list, area, state);
}
