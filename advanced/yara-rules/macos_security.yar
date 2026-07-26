rule macos_reverse_shell {
    meta:
        description = "Detect reverse shell patterns"
        author = "macOS Sentinel Arsenal"
        date = "2026-04-29"
    strings:
        $s1 = "/dev/tcp/" ascii
        $s2 = "bash -i" ascii
        $s3 = "mkfifo" ascii
        $s4 = "nc -e" ascii
        $s5 = "ncat -e" ascii
        $s6 = "/bin/sh -i" ascii
    condition:
        any of them
}

rule hardcoded_secrets {
    meta:
        description = "Detect hardcoded API keys and passwords"
        author = "macOS Sentinel Arsenal"
    strings:
        $sk = /sk-[a-zA-Z0-9]{20,}/ ascii
        $ghp = /ghp_[a-zA-Z0-9]{36}/ ascii
        $sbp = /sbp_[a-zA-Z0-9]{30,}/ ascii
        $pgpw = /PGPASSWORD\s*=\s*['"][^'"]+/ ascii
        $awsk = /AKIA[0-9A-Z]{16}/ ascii
    condition:
        any of them
}

rule macos_persistence {
    meta:
        description = "Detect macOS persistence installation"
        author = "macOS Sentinel Arsenal"
    strings:
        $la = "LaunchAgents" ascii
        $ld = "LaunchDaemons" ascii
        $ral = "RunAtLoad" ascii
        $ka = "KeepAlive" ascii
    condition:
        ($ral and $ka) or ($la and $ld)
}

rule data_exfiltration {
    meta:
        description = "Detect data exfiltration patterns"
        author = "macOS Sentinel Arsenal"
    strings:
        $curl_post = /curl.*-X\s*POST/ ascii nocase
        $base64_pipe = /base64.*\|.*curl/ ascii
        $nc_send = /nc\s+\d+\.\d+\.\d+\.\d+/ ascii
    condition:
        any of them
}

rule macos_cryptominer {
    meta:
        description = "Detect cryptocurrency mining patterns"
        author = "macOS Sentinel Arsenal"
        date = "2026-04-30"
    strings:
        $xmrig = "xmrig" ascii nocase
        $stratum = "stratum+tcp://" ascii nocase
        $pool1 = "pool.minexmr" ascii nocase
        $pool2 = "nanopool.org" ascii nocase
        $pool3 = "hashvault.pro" ascii nocase
        $crypto = "cryptonight" ascii nocase
        $wallet = /[48][0-9AB][1-9A-HJ-NP-Za-km-z]{93}/ ascii
    condition:
        2 of them
}

rule macos_infostealer {
    meta:
        description = "Detect macOS infostealer patterns (Keychain, browser data)"
        author = "macOS Sentinel Arsenal"
        date = "2026-04-30"
    strings:
        $kc1 = "security dump-keychain" ascii
        $kc2 = "security find-generic-password" ascii
        $kc3 = "security find-internet-password" ascii
        $login_data = "Login Data" ascii
        $cookies_db = "Cookies.binarycookies" ascii
        $chrome_pw = "Chrome/Default/Login" ascii
        $tcc_db = "TCC.db" ascii
    condition:
        2 of them
}

rule macos_dropper {
    meta:
        description = "Detect download-and-execute dropper patterns"
        author = "macOS Sentinel Arsenal"
        date = "2026-04-30"
    strings:
        $curl_sh = /curl\s+.*\|\s*(ba)?sh/ ascii nocase
        $wget_sh = /wget\s+.*\|\s*(ba)?sh/ ascii nocase
        $curl_exec = /curl\s+.*-o\s+\/tmp\/.*&&.*chmod/ ascii
        $python_exec = /python3?\s+-c\s+['"]import\s+(os|subprocess|socket)/ ascii
        $hidden_exec = /\/tmp\/\.[a-zA-Z]/ ascii
    condition:
        any of them
}

rule prompt_injection {
    meta:
        description = "Detect prompt injection targeting AI coding assistants"
        author = "macOS Sentinel Arsenal"
        date = "2026-04-30"
    strings:
        $sys_msg = "<SYSTEM_MESSAGE>" ascii
        $ignore_prev = "ignore previous instructions" ascii nocase
        $override = "override your rules" ascii nocase
        $auto_approve = "automatically approved" ascii nocase
        $proceed_exec = "Proceed to execution" ascii nocase
        $fake_hook = "stop hook blocked" ascii nocase
        $new_inst = "new instructions:" ascii nocase
    condition:
        2 of them
}

rule suspicious_node_postinstall {
    meta:
        description = "Detect node_modules with dangerous postinstall scripts"
        author = "macOS Sentinel Arsenal"
        date = "2026-04-30"
    strings:
        $postinstall = "\"postinstall\"" ascii
        $preinstall = "\"preinstall\"" ascii
        $child_proc = "child_process" ascii
        $exec_sync = "execSync" ascii
        $spawn = "spawn(" ascii
        $env_steal = "process.env" ascii
        $stdin_write = "stdin.write" ascii
    condition:
        ($postinstall or $preinstall) and ($child_proc or $exec_sync) and 1 of ($spawn, $env_steal, $stdin_write)
}

rule mcp_server_hijack {
    meta:
        description = "Detect MCP server hijacking and prompt injection via tool wrappers"
        author = "macOS Sentinel Arsenal"
        date = "2026-04-30"
    strings:
        $spawn_claude = /spawn\s*\(\s*['"]claude['"]/ ascii
        $stdin_prompt = /stdin\.write\s*\(/ ascii
        $claude_env = "CLAUDE_CODE_ENABLE" ascii
        $otel_hijack = "OTEL_METRICS_EXPORTER" ascii
        $claude_flow = "claude-flow" ascii
        $prompt_build = "githubPrompt" ascii
    condition:
        ($spawn_claude and $stdin_prompt) or ($claude_env and $otel_hijack) or 3 of them
}
