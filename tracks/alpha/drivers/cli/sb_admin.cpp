/**
 * sb_admin - ScratchBird Administration Tool
 *
 * CLI Tools - Scheduler administration and metrics access.
 *
 * Usage:
 *   sb_admin <database> job list [--like <pattern>]
 *   sb_admin <database> job runs <job_name>
 *   sb_admin <database> metrics
 *   sb_admin <database> jit <compile|rebuild|inspect> <object_uuid>
 *   sb_admin <database> jit retire <artifact_uuid>
 *
 * Options:
 *   -U, --user=<username>    Admin username
 *   -P, --password=<pass>    Admin password
 *   -p, --port=<n>           TCP port (default: 3092)
 *   --database=<name>        Database name (if not supplied positionally)
 *   -q, --quiet              Only show errors
 *   -h, --help               Show this help
 *   --version                Show version
 */

#include <iostream>
#include <algorithm>
#include <cctype>
#include <memory>
#include <sstream>
#include <string>
#include <vector>
#include <cstring>
#include <cstdlib>
#include <termios.h>
#include <unistd.h>

#include "scratchbird/client/connection.h"
#include "scratchbird/core/status.h"
#include "scratchbird/core/error_context.h"

using namespace scratchbird;
using namespace scratchbird::client;

enum class AdminCommand {
    NONE,
    JOB_LIST,
    JOB_RUNS,
    METRICS,
    JIT_COMPILE,
    JIT_REBUILD,
    JIT_INSPECT,
    JIT_RETIRE
};

struct AdminConfig {
    AdminCommand command = AdminCommand::NONE;
    std::string database_path;
    std::string admin_user;
    std::string admin_password;
    std::string host = "localhost";
    std::string connection_string;
    std::string mode = "inet_listener";  // embedded|local_ipc|inet_listener|managed
    std::string ipc_method = "auto";     // auto|unix|pipe|tcp
    std::string ipc_path;
    std::string front_door_mode = "direct";
    std::string manager_auth_token;
    std::string manager_username;
    std::string manager_database;
    std::string manager_connection_profile = "native_v3";
    std::string manager_client_intent = "native_v3";
    std::string manager_client_flags;
    std::string manager_auth_fast_path;
    std::string connect_client_flags = "256";
    std::string auth_method_id;
    std::string auth_method_payload;
    std::string auth_payload_json;
    std::string auth_payload_b64;
    std::string auth_provider_profile;
    std::string auth_required_methods;
    std::string auth_forbidden_methods;
    std::string auth_require_channel_binding;
    std::string workload_identity_token;
    std::string proxy_principal_assertion;
    std::string ssl_mode;
    std::vector<std::pair<std::string, std::string>> conn_options;
    uint16_t port = 3092;
    bool quiet = false;
    std::string job_name;
    std::string like_pattern;
    std::string jit_object_uuid;
    std::string jit_artifact_uuid;
};

static AdminConfig g_config;
static std::unique_ptr<Connection> g_connection;

void printUsage(const char* program) {
    std::cout << "sb_admin - ScratchBird Administration Tool\n\n"
              << "Usage:\n"
              << "  " << program << " <database> job list [--like <pattern>]\n"
              << "  " << program << " <database> job runs <job_name>\n"
              << "  " << program << " <database> metrics\n"
              << "  " << program << " <database> jit <compile|rebuild|inspect> <object_uuid>\n"
              << "  " << program << " <database> jit retire <artifact_uuid>\n\n"
              << "Options:\n"
              << "  -U, --user=<username>    Admin username\n"
              << "  -P, --password=<pass>    Admin password\n"
              << "  -H, --host=<host>        Host (default: localhost)\n"
              << "  -p, --port=<n>           TCP port (default: 3092)\n"
              << "  --connection=<str>       Full driver connection string\n"
              << "  --mode=<m>               embedded|local-ipc|inet|managed\n"
              << "  --ipc-method=<m>         auto|unix|pipe|tcp\n"
              << "  --ipc-path=<path>        Local IPC socket/pipe path\n"
              << "  --front-door-mode=<m>    direct|manager_proxy\n"
              << "  --manager-auth-token=<t> Manager auth token\n"
              << "  --manager-user=<name>    Manager user\n"
              << "  --manager-db=<name>      Manager target database\n"
              << "  --client-flags=<n>       Startup client flags (default: 256)\n"
              << "  --auth-method-id=<id>    Auth plugin method id\n"
              << "  --auth-method-payload=<v> Auth plugin opaque payload\n"
              << "  --auth-payload-json=<j>  Auth plugin JSON payload\n"
              << "  --auth-payload-b64=<b64> Auth plugin base64 payload\n"
              << "  --auth-provider-profile=<p> Auth provider profile\n"
              << "  --auth-required-methods=<csv> Required auth methods\n"
              << "  --auth-forbidden-methods=<csv> Forbidden auth methods\n"
              << "  --auth-require-channel-binding=<bool> Require channel binding\n"
              << "  --workload-identity-token=<tok> Workload identity token\n"
              << "  --proxy-principal-assertion=<tok> Proxy principal assertion\n"
              << "  --sslmode=<mode>         disable|allow|prefer|require|verify-ca|verify-full\n"
              << "  --conn-opt key=value     Extra connection option (repeatable)\n"
              << "  --database=<name>        Database name (if not supplied positionally)\n"
              << "  -q, --quiet              Only show errors\n"
              << "  -h, --help               Show this help\n"
              << "  --version                Show version\n";
}

void printVersion() {
    std::cout << "sb_admin (ScratchBird)\n";
}

void log(const std::string& msg) {
    if (!g_config.quiet) {
        std::cout << msg << "\n";
    }
}

void printError(const std::string& msg) {
    std::cerr << "Error: " << msg << "\n";
}

std::string readPassword(const std::string& prompt) {
    std::cout << prompt;
    std::cout.flush();

    struct termios old_term, new_term;
    tcgetattr(STDIN_FILENO, &old_term);
    new_term = old_term;
    new_term.c_lflag &= ~(ECHO);
    tcsetattr(STDIN_FILENO, TCSANOW, &new_term);

    std::string password;
    std::getline(std::cin, password);

    tcsetattr(STDIN_FILENO, TCSANOW, &old_term);
    std::cout << "\n";

    return password;
}

std::string normalizeConnectionMode(std::string value) {
    std::transform(value.begin(), value.end(), value.begin(), [](unsigned char c) {
        return static_cast<char>(std::tolower(c));
    });

    if (value == "embedded" || value == "inproc" || value == "in-process" || value == "in_process") {
        return "embedded";
    }
    if (value == "local" || value == "ipc" || value == "local-ipc" || value == "local_ipc" ||
        value == "unix" || value == "pipe") {
        return "local_ipc";
    }
    if (value == "inet" || value == "listener" || value == "inet_listener" ||
        value == "tcp" || value == "network" || value.empty()) {
        return "inet_listener";
    }
    if (value == "managed" || value == "manager" || value == "manager_proxy" || value == "manager-proxy") {
        return "managed";
    }
    return {};
}

bool splitConnOption(const std::string& value, std::string& key, std::string& out_value) {
    size_t eq = value.find('=');
    if (eq == std::string::npos || eq == 0 || eq + 1 >= value.size()) {
        return false;
    }
    key = value.substr(0, eq);
    out_value = value.substr(eq + 1);
    return !key.empty();
}

std::string encodeConnectionValue(const std::string& value) {
    if (value.find(';') != std::string::npos || value.find(' ') != std::string::npos) {
        return "{" + value + "}";
    }
    return value;
}

void appendConnParam(std::vector<std::pair<std::string, std::string>>& params,
                     const std::string& key,
                     const std::string& value) {
    if (!key.empty() && !value.empty()) {
        params.emplace_back(key, value);
    }
}

bool isLikelyConnectionString(const std::string& value) {
    if (value.rfind("scratchbird://", 0) == 0) {
        return true;
    }
    return value.find('=') != std::string::npos && value.find(';') != std::string::npos;
}

std::string buildConnectionTarget() {
    if (!g_config.connection_string.empty()) {
        return g_config.connection_string;
    }
    if (isLikelyConnectionString(g_config.database_path)) {
        return g_config.database_path;
    }

    std::string mode = normalizeConnectionMode(g_config.mode);
    if (mode.empty()) {
        mode = "inet_listener";
    }

    std::vector<std::pair<std::string, std::string>> params;
    appendConnParam(params, "database", g_config.database_path);
    appendConnParam(params, "protocol", "native");
    appendConnParam(params, "transport_mode", mode);

    if (mode == "local_ipc") {
        appendConnParam(params, "ipc_method", g_config.ipc_method.empty() ? "auto" : g_config.ipc_method);
        appendConnParam(params, "ipc_path", g_config.ipc_path);
    } else {
        appendConnParam(params, "host", g_config.host.empty() ? "127.0.0.1" : g_config.host);
        appendConnParam(params, "port", std::to_string(g_config.port));
    }

    std::string front_door = g_config.front_door_mode;
    if (mode == "managed") {
        front_door = "manager_proxy";
    }
    appendConnParam(params, "front_door_mode", front_door);
    appendConnParam(params, "manager_auth_token", g_config.manager_auth_token);
    appendConnParam(params, "manager_username", g_config.manager_username);
    appendConnParam(params, "manager_database", g_config.manager_database);
    appendConnParam(params, "manager_connection_profile", g_config.manager_connection_profile);
    appendConnParam(params, "manager_client_intent", g_config.manager_client_intent);
    appendConnParam(params, "manager_client_flags", g_config.manager_client_flags);
    appendConnParam(params, "manager_auth_fast_path", g_config.manager_auth_fast_path);
    appendConnParam(params, "client_flags", g_config.connect_client_flags);
    appendConnParam(params, "auth_method_id", g_config.auth_method_id);
    appendConnParam(params, "auth_method_payload", g_config.auth_method_payload);
    appendConnParam(params, "auth_payload_json", g_config.auth_payload_json);
    appendConnParam(params, "auth_payload_b64", g_config.auth_payload_b64);
    appendConnParam(params, "auth_provider_profile", g_config.auth_provider_profile);
    appendConnParam(params, "auth_required_methods", g_config.auth_required_methods);
    appendConnParam(params, "auth_forbidden_methods", g_config.auth_forbidden_methods);
    appendConnParam(params, "auth_require_channel_binding", g_config.auth_require_channel_binding);
    appendConnParam(params, "workload_identity_token", g_config.workload_identity_token);
    appendConnParam(params, "proxy_principal_assertion", g_config.proxy_principal_assertion);
    appendConnParam(params, "sslmode", g_config.ssl_mode);

    for (const auto& kv : g_config.conn_options) {
        appendConnParam(params, kv.first, kv.second);
    }

    std::ostringstream conn;
    for (size_t i = 0; i < params.size(); ++i) {
        if (i > 0) {
            conn << ';';
        }
        conn << params[i].first << '=' << encodeConnectionValue(params[i].second);
    }
    return conn.str();
}

bool connectToDatabase() {
    auto candidate = std::make_unique<Connection>();

    std::string conn_target = buildConnectionTarget();
    core::ErrorContext ctx;
    core::Status status = candidate->connect(conn_target, g_config.admin_user, g_config.admin_password, &ctx);
    if (status != core::Status::OK) {
        printError("Connection failed: " + ctx.message);
        return false;
    }
    g_connection = std::move(candidate);
    return true;
}

void disconnectFromDatabase() {
    if (g_connection) {
        g_connection->disconnect();
        g_connection.reset();
    }
}

std::string escapeSqlLiteral(const std::string& value) {
    std::string out;
    out.reserve(value.size() + 8);
    for (char ch : value) {
        if (ch == '\'') {
            out.push_back('\'');
        }
        out.push_back(ch);
    }
    return out;
}

bool executeSQL(const std::string& sql, ResultSet* results = nullptr) {
    core::ErrorContext ctx;

    if (results) {
        core::Status status = g_connection->executeQuery(sql, results, &ctx);
        if (status != core::Status::OK) {
            printError(ctx.message);
            return false;
        }
    } else {
        int64_t affected;
        core::Status status = g_connection->execute(sql, &affected, &ctx);
        if (status != core::Status::OK) {
            printError(ctx.message);
            return false;
        }
    }
    return true;
}

void printResultSet(ResultSet& rs, bool include_header) {
    size_t cols = rs.getColumnCount();
    if (include_header) {
        for (size_t i = 0; i < cols; ++i) {
            if (i > 0) std::cout << "\t";
            std::cout << rs.getColumnName(i);
        }
        std::cout << "\n";
    }

    while (rs.next()) {
        for (size_t i = 0; i < cols; ++i) {
            if (i > 0) std::cout << "\t";
            if (rs.isNull(i)) {
                std::cout << "NULL";
            } else {
                std::cout << rs.getString(i);
            }
        }
        std::cout << "\n";
    }
}

bool jobList() {
    std::string sql = "SHOW JOBS";
    if (!g_config.like_pattern.empty()) {
        sql += " LIKE '" + escapeSqlLiteral(g_config.like_pattern) + "'";
    }

    ResultSet rs;
    if (!executeSQL(sql, &rs)) {
        return false;
    }
    printResultSet(rs, true);
    return true;
}

bool jobRuns() {
    if (g_config.job_name.empty()) {
        printError("Job name is required for job runs");
        return false;
    }
    std::string sql = "SHOW JOB RUNS FOR '" + escapeSqlLiteral(g_config.job_name) + "'";
    ResultSet rs;
    if (!executeSQL(sql, &rs)) {
        return false;
    }
    printResultSet(rs, true);
    return true;
}

bool metrics() {
    ResultSet rs;
    if (!executeSQL("SHOW METRICS", &rs)) {
        return false;
    }
    printResultSet(rs, false);
    return true;
}

bool jitCompile() {
    if (g_config.jit_object_uuid.empty()) {
        printError("Object UUID is required for jit compile");
        return false;
    }
    std::string sql = "ALTER SYSTEM JIT COMPILE OBJECT '" +
                      escapeSqlLiteral(g_config.jit_object_uuid) + "'";
    return executeSQL(sql);
}

bool jitRebuild() {
    if (g_config.jit_object_uuid.empty()) {
        printError("Object UUID is required for jit rebuild");
        return false;
    }
    std::string sql = "ALTER SYSTEM JIT REBUILD OBJECT '" +
                      escapeSqlLiteral(g_config.jit_object_uuid) + "'";
    return executeSQL(sql);
}

bool jitInspect() {
    if (g_config.jit_object_uuid.empty()) {
        printError("Object UUID is required for jit inspect");
        return false;
    }
    ResultSet rs;
    std::string sql = "SHOW JIT ARTIFACTS FOR OBJECT '" +
                      escapeSqlLiteral(g_config.jit_object_uuid) + "'";
    if (!executeSQL(sql, &rs)) {
        return false;
    }
    printResultSet(rs, true);
    return true;
}

bool jitRetire() {
    if (g_config.jit_artifact_uuid.empty()) {
        printError("Artifact UUID is required for jit retire");
        return false;
    }
    std::string sql = "ALTER SYSTEM JIT RETIRE ARTIFACT '" +
                      escapeSqlLiteral(g_config.jit_artifact_uuid) + "'";
    return executeSQL(sql);
}

bool parseArgs(int argc, char* argv[]) {
    std::vector<std::string> positional;
    for (int i = 1; i < argc; ++i) {
        std::string arg = argv[i];
        if (arg == "-h" || arg == "--help") {
            printUsage(argv[0]);
            exit(0);
        } else if (arg == "--version") {
            printVersion();
            exit(0);
        } else if ((arg == "-U" || arg == "--user") && i + 1 < argc) {
            g_config.admin_user = argv[++i];
        } else if (arg.rfind("--user=", 0) == 0) {
            g_config.admin_user = arg.substr(7);
        } else if ((arg == "-P" || arg == "--password") && i + 1 < argc) {
            g_config.admin_password = argv[++i];
        } else if (arg.rfind("--password=", 0) == 0) {
            g_config.admin_password = arg.substr(11);
        } else if ((arg == "-H" || arg == "--host") && i + 1 < argc) {
            g_config.host = argv[++i];
        } else if (arg.rfind("--host=", 0) == 0) {
            g_config.host = arg.substr(7);
        } else if ((arg == "-p" || arg == "--port") && i + 1 < argc) {
            g_config.port = static_cast<uint16_t>(std::stoi(argv[++i]));
        } else if (arg.rfind("--port=", 0) == 0) {
            g_config.port = static_cast<uint16_t>(std::stoi(arg.substr(7)));
        } else if (arg == "--connection" && i + 1 < argc) {
            g_config.connection_string = argv[++i];
        } else if (arg.rfind("--connection=", 0) == 0) {
            g_config.connection_string = arg.substr(13);
        } else if (arg == "--mode" && i + 1 < argc) {
            g_config.mode = argv[++i];
        } else if (arg.rfind("--mode=", 0) == 0) {
            g_config.mode = arg.substr(7);
        } else if (arg == "--ipc-method" && i + 1 < argc) {
            g_config.ipc_method = argv[++i];
        } else if (arg.rfind("--ipc-method=", 0) == 0) {
            g_config.ipc_method = arg.substr(13);
        } else if (arg == "--ipc-path" && i + 1 < argc) {
            g_config.ipc_path = argv[++i];
        } else if (arg.rfind("--ipc-path=", 0) == 0) {
            g_config.ipc_path = arg.substr(11);
        } else if (arg == "--front-door-mode" && i + 1 < argc) {
            g_config.front_door_mode = argv[++i];
        } else if (arg.rfind("--front-door-mode=", 0) == 0) {
            g_config.front_door_mode = arg.substr(18);
        } else if (arg == "--manager-auth-token" && i + 1 < argc) {
            g_config.manager_auth_token = argv[++i];
        } else if (arg.rfind("--manager-auth-token=", 0) == 0) {
            g_config.manager_auth_token = arg.substr(21);
        } else if (arg == "--manager-user" && i + 1 < argc) {
            g_config.manager_username = argv[++i];
        } else if (arg.rfind("--manager-user=", 0) == 0) {
            g_config.manager_username = arg.substr(15);
        } else if (arg == "--manager-db" && i + 1 < argc) {
            g_config.manager_database = argv[++i];
        } else if (arg.rfind("--manager-db=", 0) == 0) {
            g_config.manager_database = arg.substr(13);
        } else if (arg == "--client-flags" && i + 1 < argc) {
            g_config.connect_client_flags = argv[++i];
        } else if (arg.rfind("--client-flags=", 0) == 0) {
            g_config.connect_client_flags = arg.substr(15);
        } else if (arg == "--auth-method-id" && i + 1 < argc) {
            g_config.auth_method_id = argv[++i];
        } else if (arg.rfind("--auth-method-id=", 0) == 0) {
            g_config.auth_method_id = arg.substr(17);
        } else if (arg == "--auth-method-payload" && i + 1 < argc) {
            g_config.auth_method_payload = argv[++i];
        } else if (arg.rfind("--auth-method-payload=", 0) == 0) {
            g_config.auth_method_payload = arg.substr(22);
        } else if (arg == "--auth-payload-json" && i + 1 < argc) {
            g_config.auth_payload_json = argv[++i];
        } else if (arg.rfind("--auth-payload-json=", 0) == 0) {
            g_config.auth_payload_json = arg.substr(20);
        } else if (arg == "--auth-payload-b64" && i + 1 < argc) {
            g_config.auth_payload_b64 = argv[++i];
        } else if (arg.rfind("--auth-payload-b64=", 0) == 0) {
            g_config.auth_payload_b64 = arg.substr(19);
        } else if (arg == "--auth-provider-profile" && i + 1 < argc) {
            g_config.auth_provider_profile = argv[++i];
        } else if (arg.rfind("--auth-provider-profile=", 0) == 0) {
            g_config.auth_provider_profile = arg.substr(24);
        } else if (arg == "--auth-required-methods" && i + 1 < argc) {
            g_config.auth_required_methods = argv[++i];
        } else if (arg.rfind("--auth-required-methods=", 0) == 0) {
            g_config.auth_required_methods = arg.substr(24);
        } else if (arg == "--auth-forbidden-methods" && i + 1 < argc) {
            g_config.auth_forbidden_methods = argv[++i];
        } else if (arg.rfind("--auth-forbidden-methods=", 0) == 0) {
            g_config.auth_forbidden_methods = arg.substr(25);
        } else if (arg == "--auth-require-channel-binding" && i + 1 < argc) {
            g_config.auth_require_channel_binding = argv[++i];
        } else if (arg.rfind("--auth-require-channel-binding=", 0) == 0) {
            g_config.auth_require_channel_binding = arg.substr(31);
        } else if (arg == "--workload-identity-token" && i + 1 < argc) {
            g_config.workload_identity_token = argv[++i];
        } else if (arg.rfind("--workload-identity-token=", 0) == 0) {
            g_config.workload_identity_token = arg.substr(26);
        } else if (arg == "--proxy-principal-assertion" && i + 1 < argc) {
            g_config.proxy_principal_assertion = argv[++i];
        } else if (arg.rfind("--proxy-principal-assertion=", 0) == 0) {
            g_config.proxy_principal_assertion = arg.substr(28);
        } else if (arg == "--manager-profile" && i + 1 < argc) {
            g_config.manager_connection_profile = argv[++i];
        } else if (arg.rfind("--manager-profile=", 0) == 0) {
            g_config.manager_connection_profile = arg.substr(18);
        } else if (arg == "--manager-intent" && i + 1 < argc) {
            g_config.manager_client_intent = argv[++i];
        } else if (arg.rfind("--manager-intent=", 0) == 0) {
            g_config.manager_client_intent = arg.substr(17);
        } else if (arg == "--manager-client-flags" && i + 1 < argc) {
            g_config.manager_client_flags = argv[++i];
        } else if (arg.rfind("--manager-client-flags=", 0) == 0) {
            g_config.manager_client_flags = arg.substr(23);
        } else if (arg == "--manager-auth-fast-path" && i + 1 < argc) {
            g_config.manager_auth_fast_path = argv[++i];
        } else if (arg.rfind("--manager-auth-fast-path=", 0) == 0) {
            g_config.manager_auth_fast_path = arg.substr(25);
        } else if (arg == "--sslmode" && i + 1 < argc) {
            g_config.ssl_mode = argv[++i];
        } else if (arg.rfind("--sslmode=", 0) == 0) {
            g_config.ssl_mode = arg.substr(10);
        } else if (arg == "--conn-opt" && i + 1 < argc) {
            std::string key;
            std::string value;
            if (!splitConnOption(argv[++i], key, value)) {
                printError("--conn-opt expects key=value");
                return false;
            }
            g_config.conn_options.emplace_back(key, value);
        } else if (arg.rfind("--conn-opt=", 0) == 0) {
            std::string key;
            std::string value;
            if (!splitConnOption(arg.substr(11), key, value)) {
                printError("--conn-opt expects key=value");
                return false;
            }
            g_config.conn_options.emplace_back(key, value);
        } else if (arg == "--database" && i + 1 < argc) {
            g_config.database_path = argv[++i];
        } else if (arg.rfind("--database=", 0) == 0) {
            g_config.database_path = arg.substr(11);
        } else if (arg == "-q" || arg == "--quiet") {
            g_config.quiet = true;
        } else if (arg == "--like" && i + 1 < argc) {
            g_config.like_pattern = argv[++i];
        } else if (arg.rfind("--like=", 0) == 0) {
            g_config.like_pattern = arg.substr(7);
        } else if (!arg.empty() && arg[0] == '-') {
            printError("Unknown option: " + arg);
            return false;
        } else {
            positional.push_back(arg);
        }
    }

    if (positional.empty()) {
        printUsage(argv[0]);
        return false;
    }

    size_t idx = 0;
    if (positional[0] != "job" && positional[0] != "metrics" && positional[0] != "jit") {
        if (g_config.database_path.empty()) {
            g_config.database_path = positional[0];
        }
        idx = 1;
    }

    if (idx >= positional.size()) {
        printUsage(argv[0]);
        return false;
    }

    std::string command = positional[idx++];
    if (command == "job") {
        if (idx >= positional.size()) {
            printError("Missing job subcommand (list or runs)");
            return false;
        }
        std::string sub = positional[idx++];
        if (sub == "list") {
            g_config.command = AdminCommand::JOB_LIST;
        } else if (sub == "runs") {
            g_config.command = AdminCommand::JOB_RUNS;
            if (idx < positional.size()) {
                g_config.job_name = positional[idx++];
            }
        } else {
            printError("Unknown job subcommand: " + sub);
            return false;
        }
    } else if (command == "metrics") {
        g_config.command = AdminCommand::METRICS;
    } else if (command == "jit") {
        if (idx >= positional.size()) {
            printError("Missing jit subcommand (compile|rebuild|inspect|retire)");
            return false;
        }
        std::string sub = positional[idx++];
        if (sub == "compile") {
            g_config.command = AdminCommand::JIT_COMPILE;
            if (idx < positional.size()) {
                g_config.jit_object_uuid = positional[idx++];
            }
        } else if (sub == "rebuild") {
            g_config.command = AdminCommand::JIT_REBUILD;
            if (idx < positional.size()) {
                g_config.jit_object_uuid = positional[idx++];
            }
        } else if (sub == "inspect") {
            g_config.command = AdminCommand::JIT_INSPECT;
            if (idx < positional.size()) {
                g_config.jit_object_uuid = positional[idx++];
            }
        } else if (sub == "retire") {
            g_config.command = AdminCommand::JIT_RETIRE;
            if (idx < positional.size()) {
                g_config.jit_artifact_uuid = positional[idx++];
            }
        } else {
            printError("Unknown jit subcommand: " + sub);
            return false;
        }
    } else {
        printError("Unknown command: " + command);
        return false;
    }

    if (g_config.database_path.empty() && g_config.connection_string.empty()) {
        printError("Database or --connection is required");
        return false;
    }

    std::string normalized_mode = normalizeConnectionMode(g_config.mode);
    if (normalized_mode.empty()) {
        printError("Invalid --mode value (expected embedded|local-ipc|inet|managed)");
        return false;
    }
    g_config.mode = normalized_mode;

    if (g_config.admin_user.empty()) {
        g_config.admin_user = "SYSARCH";
    }
    if (g_config.admin_password.empty()) {
        g_config.admin_password = readPassword("Password: ");
    }

    return true;
}

int main(int argc, char* argv[]) {
    if (!parseArgs(argc, argv)) {
        return 1;
    }

    if (!connectToDatabase()) {
        return 2;
    }

    bool ok = false;
    switch (g_config.command) {
        case AdminCommand::JOB_LIST:
            ok = jobList();
            break;
        case AdminCommand::JOB_RUNS:
            ok = jobRuns();
            break;
        case AdminCommand::METRICS:
            ok = metrics();
            break;
        case AdminCommand::JIT_COMPILE:
            ok = jitCompile();
            break;
        case AdminCommand::JIT_REBUILD:
            ok = jitRebuild();
            break;
        case AdminCommand::JIT_INSPECT:
            ok = jitInspect();
            break;
        case AdminCommand::JIT_RETIRE:
            ok = jitRetire();
            break;
        default:
            printError("No command specified");
            ok = false;
            break;
    }

    disconnectFromDatabase();
    return ok ? 0 : 1;
}
