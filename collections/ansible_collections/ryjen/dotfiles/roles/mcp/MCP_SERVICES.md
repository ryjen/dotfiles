# MCP Services Documentation

This document provides an overview of the MCP services defined in `docker-compose.yml`, including their purpose, repository URLs, and specific configurations.

---

## 🌐 MCP Gateway

**Service Name**: `mcp-gateway`
**Description**: The central gateway for the Multi-Agent Communication Protocol (MCP), routing requests to various MCP services.
**Image**: `docker/mcp-gateway:v0.33.0`
**Ports**: `11535:8080`
**Volumes**: `./adapters.yml:/etc/mcp-gateway/adapters.yml`
**Dependencies**:
_Note: The gateway currently lists all other services in `depends_on`. While this ensures startup order, re-evaluating these dependencies to include only truly essential services for the gateway's operation could optimize resource usage and improve startup times in the future._
- `sequential-thinking`
- `filesystem`
- `arxiv-mcp`
- `local-rag-mcp`
- `taskwarrior-mcp`
- `mermaid-diagrams`
- `opentofu`
- `sysoperator`
- `conventional-commits`
- `shrimp-task-manager`
- `user-feedback-mcp`
- `hub-mcp`
- `postman-mcp`
- `kubectl-mcp`
- `gradle-mcp`
- `language-mcp`
- `editorconfig-mcp`
- `semgrep-mcp`
- `fetch-mcp`
- `src-to-kb`
- `pandoc-mcp`
- `piloty-mcp`
- `kaggle-mcp`
- `context-awesome`
- `summarizer-mcp`
- `chatsum-mcp`
- `mobsf-mcp`
- `ghidra-mcp`
- `mcp-scan`
- `calculator-mcp`
- `investor-agent`
- `docker-mcp`
- `token-optimizer-mcp`

---

## Environment Variable Management Best Practices

For services requiring sensitive information like API keys, it's recommended to use a `.env` file to manage these variables securely, keeping them out of version control.

**Example Implementation:**
The `kaggle-mcp` and `mobsf-mcp` services have been updated to reference environment variables directly from a `.env` file. A sample `.env` file (`.env.example`) has been provided to guide users on setting up these variables. Users should create their own `.env` file based on the example and ensure it's added to `.gitignore`.

This approach enhances security by separating sensitive credentials from the main configuration.

## 🧠 Core MCP Utilities

_Note on Commands: While most Node.js services use `node index.js` or `node server.js` for their `command`, variations like `npm run start:streamable` or `npm build && npm start` are present. These variations are typically intentional and reflect specific build processes or custom startup scripts defined within the respective project repositories._

### `sequential-thinking`
**Description**: Provides reasoning and chain-of-thought capabilities for the MCP system.
**Image**: `mcp/sequentialthinking:latest`
**Restart Policy**: `unless-stopped`

### `filesystem`
**Description**: Grants local filesystem access to MCP agents.
**Image**: `mcp/filesystem:latest`
**Volumes**: `/home/ryjen/Projects:/projects`
**Restart Policy**: `unless-stopped`

### `arxiv-mcp`
**Description**: Integrates with Arxiv for accessing scientific papers.
**Image**: `mcp/arxiv-mcp-server:latest`
**Restart Policy**: `unless-stopped`

### `local-rag-mcp`
**Description**: Provides retrieval-augmented generation capabilities.
**Repository URL**: `https://github.com/shinpr/mcp-local-rag.git`
**Dockerfile**: `Dockerfile.node-mcp`
**Restart Policy**: `unless-stopped`

### `taskwarrior-mcp`
**Description**: Integrates with Taskwarrior for task management.
**Repository URL**: `https://github.com/awwaiid/mcp-server-taskwarrior.git`
**Dockerfile**: `Dockerfile.node-mcp`
**Volumes**: `~/.task:/root/.task`
**Restart Policy**: `unless-stopped`

### `mermaid-diagrams`
**Description**: Generates diagrams using Mermaid syntax.
**Repository URL**: `https://github.com/hustcc/mcp-mermaid.git`
**Dockerfile**: `Dockerfile.node-mcp`
**Command**: `npm run start:streamable`
**Restart Policy**: `unless-stopped`

### `opentofu`
**Description**: Provides infrastructure-as-code capabilities, likely integrating with OpenTofu.
**Repository URL**: `https://github.com/opentofu/opentofu-mcp-server.git`
**Dockerfile**: `Dockerfile.node-mcp`
**Restart Policy**: `unless-stopped`

### `sysoperator`
**Description**: A helper for system operations.
**Repository URL**: `https://github.com/tarnover/mcp-sysoperator.git`
**Dockerfile**: `Dockerfile.node-mcp`
**Command**: `npm build && npm start`
**Restart Policy**: `unless-stopped`

### `conventional-commits`
**Description**: Enforces conventional commit message standards.
**Image**: `ghcr.io/theoklitosbam7/mcp-git-commit-generator:latest`
**Restart Policy**: `unless-stopped`

---

## 📋 Task & Project Management

### `shrimp-task-manager`
**Description**: A task manager, likely GitHub-oriented.
**Repository URL**: `https://github.com/cjo4m06/mcp-shrimp-task-manager.git`
**Dockerfile**: `Dockerfile.node-mcp`
**Command**: `node server.js`
**Restart Policy**: `unless-stopped`

### `user-feedback-mcp`
**Description**: Handles user feedback for the MCP system.
**Repository URL**: `https://github.com/mrexodia/user-feedback-mcp.git`
**Dockerfile**: `Dockerfile.node-mcp`
**Command**: `node index.js`
**Restart Policy**: `unless-stopped`

---

## 🔧 Developer Tools & Code Analysis

### `hub-mcp`
**Description**: Integrates with Docker Hub or a similar hub service.
**Repository URL**: `https://github.com/docker/hub-mcp.git`
**Dockerfile**: `Dockerfile.node-mcp`
**Command**: `node server.js`
**Restart Policy**: `unless-stopped`

### `postman-mcp`
**Description**: Integrates with Postman for API development and testing.
**Repository URL**: `https://github.com/delano/postman-mcp-server.git`
**Dockerfile**: `Dockerfile.node-mcp`
**Command**: `node index.js`
**Restart Policy**: `unless-stopped`

### `kubectl-mcp`
**Description**: Provides Kubernetes control (kubectl) capabilities to MCP agents.
**Repository URL**: `https://github.com/rohitg00/kubectl-mcp-server.git`
**Dockerfile**: `Dockerfile.node-mcp`
**Command**: `node server.js`
**Volumes**: `~/.kube:/root/.kube`
**Restart Policy**: `unless-stopped`

### `gradle-mcp`
**Description**: Integrates with Gradle build automation tool.
**Repository URL**: `https://github.com/IlyaGulya/gradle-mcp-server.git`
**Dockerfile**: `Dockerfile.node-mcp`
**Command**: `./gradlew run`
**Restart Policy**: `unless-stopped`

### `language-mcp`
**Description**: A language server for MCP.
**Repository URL**: `https://github.com/isaacphi/mcp-language-server.git`
**Dockerfile**: `Dockerfile.node-mcp`
**Command**: `node index.js`
**Restart Policy**: `unless-stopped`

### `editorconfig-mcp`
**Description**: Integrates with EditorConfig for consistent coding styles.
**Repository URL**: `https://github.com/neilberkman/editorconfig_mcp.git`
**Dockerfile**: `Dockerfile.node-mcp`
**Command**: `node server.js`
**Restart Policy**: `unless-stopped`

### `semgrep-mcp`
**Description**: Integrates with Semgrep for static analysis and security checks.
**Repository URL**: `https://github.com/semgrep/semgrep.git`
**Dockerfile**: `Dockerfile.python-mcp`
**Working Directory**: `/app/cli/src/semgrep/mcp`
**Command**: `python -m semgrep.mcp`
**Restart Policy**: `unless-stopped`

---

## 📚 Data & Knowledge Sources

### `fetch-mcp`
**Description**: Provides fetching capabilities, likely for web content or data.
**Repository URL**: `https://github.com/zcaceres/fetch-mcp.git`
**Dockerfile**: `Dockerfile.node-mcp`
**Command**: `node index.js`
**Restart Policy**: `unless-stopped`

### `src-to-kb`
**Description**: Converts source code to a knowledge base.
**Repository URL**: `https://github.com/vezlo/src-to-kb.git`
**Dockerfile**: `Dockerfile.node-mcp`
**Command**: `node server.js`
**Restart Policy**: `unless-stopped`

### `pandoc-mcp`
**Description**: Integrates with Pandoc for document conversion.
**Repository URL**: `https://github.com/vivekVells/mcp-pandoc.git`
**Dockerfile**: `Dockerfile.python-mcp`
**Command**: `python main.py`
**Restart Policy**: `unless-stopped`

### `piloty-mcp`
**Description**: Likely a pilot assistance or automation tool.
**Repository URL**: `https://github.com/yiwenlu66/PiloTY.git`
**Dockerfile**: `Dockerfile.node-mcp`
**Command**: `node index.js`
**Restart Policy**: `unless-stopped`

### `kaggle-mcp`
**Description**: Integrates with Kaggle for data science competitions and datasets.
**Repository URL**: `https://github.com/arrismo/kaggle-mcp.git`
**Dockerfile**: `Dockerfile.node-mcp`
**Command**: `node server.js`
**Environment Variables**:
- `KAGGLE_USERNAME`: `your_username` (placeholder)
- `KAGGLE_KEY`: `your_api_key` (placeholder)
**Restart Policy**: `unless-stopped`

### `context-awesome`
**Description**: Provides context-aware functionalities.
**Repository URL**: `https://github.com/bh-rat/context-awesome.git`
**Dockerfile**: `Dockerfile.node-mcp`
**Command**: `node index.js`
**Restart Policy**: `unless-stopped`

### `summarizer-mcp`
**Description**: Provides text summarization capabilities.
**Repository URL**: `https://github.com/0xshellming/mcp-summarizer.git`
**Dockerfile**: `Dockerfile.node-mcp`
**Command**: `node index.js`
**Restart Policy**: `unless-stopped`

### `chatsum-mcp`
**Description**: Provides chat summarization capabilities.
**Repository URL**: `https://github.com/chatmcp/mcp-server-chatsum.git`
**Dockerfile**: `Dockerfile.node-mcp`
**Command**: `node index.js`
**Restart Policy**: `unless-stopped`

---

## 🔒 Security & Reverse Engineering

### `mobsf-mcp`
**Description**: Integrates with Mobile Security Framework (MobSF) for mobile app security analysis.
**Repository URL**: `https://github.com/pullkitsan/mobsf-mcp-server.git`
**Dockerfile**: `Dockerfile.node-mcp`
**Environment Variables**:
- `MOBSF_API_KEY`: `key` (placeholder)
- `MOBSF_URL`: `url` (placeholder)
**Restart Policy**: `unless-stopped`

### `ghidra-mcp`
**Description**: Integrates with Ghidra, a software reverse engineering (SRE) suite.
**Repository URL**: `https://github.com/13bm/GhidraMCP.git`
**Dockerfile**: `Dockerfile.node-mcp`
**Command**: `./gradlew run`
**Restart Policy**: `unless-stopped`

### `mcp-scan`
**Description**: Provides scanning capabilities, likely for security or vulnerability analysis.
**Repository URL**: `https://github.com/invariantlabs-ai/mcp-scan.git`
**Dockerfile**: `Dockerfile.node-mcp`
**Command**: `node index.js`
**Restart Policy**: `unless-stopped`

---

## 💡 Miscellaneous Utilities

### `calculator-mcp`
**Description**: Provides calculator functionalities.
**Repository URL**: `https://github.com/avisangle/calculator-server.git`
**Dockerfile**: `Dockerfile.node-mcp`
**Command**: `node index.js`
**Restart Policy**: `unless-stopped`

### `investor-agent`
**Description**: An agent for investor-related tasks.
**Repository URL**: `https://github.com/ferdousbhai/investor-agent.git`
**Dockerfile**: `Dockerfile.python-mcp`
**Command**: `uvx investor-agent`
**Restart Policy**: `unless-stopped`

### `docker-mcp`
**Description**: Integrates with Docker for managing Docker resources.
**Repository URL**: `https://github.com/QuantGeekDev/docker-mcp.git`
**Dockerfile**: `Dockerfile.node-mcp`
**Command**: `node index.js`
**Restart Policy**: `unless-stopped`

### `token-optimizer-mcp`
**Description**: Optimizes tokens, likely for language models or similar applications.
**Repository URL**: `https://github.com/ooples/token-optimizer-mcp.git`
**Dockerfile**: `Dockerfile.node-mcp`
**Command**: `node index.js`
**Restart Policy**: `unless-stopped`
