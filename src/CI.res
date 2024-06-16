@val @scope("process.env") external ci: string = "CI"

let isRunningInCI = switch ci {
| "1" | "true" | "TRUE" => true
| _ => false
}
