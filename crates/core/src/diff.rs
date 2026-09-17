use serde_json::Value;

#[derive(Debug, Clone, PartialEq)]
pub enum Action {
    Create,
    Update,
    Delete,
    NoOp,
}

#[derive(Debug, Clone)]
pub struct FieldDiff {
    pub path: String,
    pub before: Option<String>,
    pub after: Option<String>,
    pub action: Action,
}

fn trunc(s: &str) -> String {
    const N: usize = 120;
    if s.len() > N {
        format!("{}…", &s[..N])
    } else {
        s.to_string()
    }
}

pub fn compute_diff(before: &Value, after: &Value) -> Vec<FieldDiff> {
    let mut out = Vec::new();
    rec("", before, after, &mut out);
    out
}

fn rec(path: &str, b: &Value, a: &Value, out: &mut Vec<FieldDiff>) {
    match (b, a) {
        (Value::Object(bm), Value::Object(am)) => {
            for (k, bv) in bm {
                let p = if path.is_empty() {
                    k.clone()
                } else {
                    format!("{path}.{k}")
                };
                match am.get(k) {
                    Some(av) => rec(&p, bv, av, out),
                    None => out.push(FieldDiff {
                        path: p,
                        before: Some(trunc(&bv.to_string())),
                        after: None,
                        action: Action::Delete,
                    }),
                }
            }
            for (k, av) in am {
                if !bm.contains_key(k) {
                    let p = if path.is_empty() {
                        k.clone()
                    } else {
                        format!("{path}.{k}")
                    };
                    out.push(FieldDiff {
                        path: p,
                        before: None,
                        after: Some(trunc(&av.to_string())),
                        action: Action::Create,
                    });
                }
            }
        }
        (Value::Array(ba), Value::Array(aa)) => {
            let n = ba.len().max(aa.len());
            for i in 0..n {
                let p = format!("{path}[{i}]");
                match (ba.get(i), aa.get(i)) {
                    (Some(x), Some(y)) => rec(&p, x, y, out),
                    (Some(x), None) => out.push(FieldDiff {
                        path: p,
                        before: Some(trunc(&x.to_string())),
                        after: None,
                        action: Action::Delete,
                    }),
                    (None, Some(y)) => out.push(FieldDiff {
                        path: p,
                        before: None,
                        after: Some(trunc(&y.to_string())),
                        action: Action::Create,
                    }),
                    (None, None) => {}
                }
            }
        }
        (x, y) => {
            if x != y {
                out.push(FieldDiff {
                    path: path.to_string(),
                    before: Some(trunc(&x.to_string())),
                    after: Some(trunc(&y.to_string())),
                    action: Action::Update,
                });
            }
        }
    }
}

/// Summarize `terraform show -json` resource_changes into (add, change, delete).
pub fn plan_summary(plan: &Value) -> (u32, u32, u32) {
    let mut add = 0u32;
    let mut change = 0u32;
    let mut del = 0u32;
    if let Some(rc) = plan.get("resource_changes").and_then(|v| v.as_array()) {
        for r in rc {
            let actions = r
                .get("change")
                .and_then(|c| c.get("actions"))
                .and_then(|a| a.as_array());
            if let Some(actions) = actions {
                let acts: Vec<&str> = actions.iter().filter_map(|v| v.as_str()).collect();
                if acts.contains(&"create") {
                    add += 1;
                } else if acts.contains(&"delete") && acts.contains(&"create") {
                    change += 1;
                } else if acts.contains(&"delete") {
                    del += 1;
                } else if acts.contains(&"update") {
                    change += 1;
                }
            }
        }
    }
    (add, change, del)
}
