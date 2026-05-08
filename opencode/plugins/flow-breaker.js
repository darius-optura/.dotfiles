export const FlowBreaker = async ({ $ }) => {
  let cached = ""

  const refresh = async () => {
    try {
      cached = await $`flow-breaker nudge`.quiet().nothrow().text()
    } catch {
      cached = ""
    }
  }
  await refresh()
  setInterval(refresh, 30 * 60 * 1000)

  return {
    "experimental.chat.system.transform": async (input, output) => {
      if (cached.trim()) {
        output.system.push("## flow-breaker alerts\n" + cached.trim())
      }
    },
  }
}
