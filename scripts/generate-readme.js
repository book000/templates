const fs = require("fs");
const jsyaml = require("js-yaml");

function getWorkflowText(path) {
  const filename = path.split("/").pop();
  const contents = [
    `### ${filename}`,
    "",
    "```shell",
    `mkdir -p .github/workflows ; wget -O .github/workflows/hadolint-multi-ci.yml https://raw.githubusercontent.com/book000/templates/master/workflows/${filename}`,
    "```",
  ];

  const workflow = fs.readFileSync(path, "utf8");
  const uses = workflow.match(/uses: book000\/templates\/(.*)@(.+)/);
  if (!uses) {
    return contents.join("\n");
  }

  const [_, reusablePath, version] = uses;
  const reusableRaw = fs.readFileSync(reusablePath, "utf8");
  const reusable = jsyaml.load(reusableRaw);

  if (!reusable.on || !reusable.on.workflow_call) {
    return contents.join("\n");
  }

  const inputs = reusable.on.workflow_call.inputs;
  const headers = ["Required", "Key", "Description", "Type", "Default"];
  const inputsText = Object.keys(inputs).map((key) => {
    const input = inputs[key];
    const required = input.required ? "✔" : "";
    const description = input.description || "";
    const type = input.type ? `\`${input.type}\`` : "";
    const defaultVal = input.default ? `\`${input.default}\`` : "";
    const line = [
      required,
      `\`${key}\``,
      description,
      type,
      defaultVal,
    ].join(" | ");
    return `| ${line} |`;
  });
  contents.push("");
  contents.push(`| ${headers.join(" | ")} |`);
  contents.push(`| ${headers.map(() => "---").join(" | ")} |`);
  contents.push(...inputsText);
  return contents.join("\n");
}

function generateWorkflowFiles(templates) {
  const dir = "./workflows";
  const workflowFiles = fs
    .readdirSync(dir)
    .filter((file) => file.endsWith(".yml"))
    .map((file) => `${dir}/${file}`);
  const workflowTexts = workflowFiles.map((path) => getWorkflowText(path));
  const workflowText = workflowTexts.join("\n\n");
  return templates.replace(/<!-- gw-templates -->/g, `${workflowText}`);
}

function getDockerText(path) {
  const filename = path.split("/").pop();
  const contents = [
    `### ${filename}`,
    "",
    "```shell",
    `wget -O Dockerfile https://raw.githubusercontent.com/book000/templates/master/dockerfiles/${filename}`,
    "```",
  ];
  return contents.join("\n");
}

function generateDockerFiles(templates) {
  const dir = "./dockerfiles";
  const dockerFiles = fs
    .readdirSync(dir)
    .filter((file) => file.endsWith(".Dockerfile"))
    .map((file) => `${dir}/${file}`);
  const dockerTexts = dockerFiles.map((path) => getDockerText(path));
  const dockerText = dockerTexts.join("\n\n");
  return templates.replace(/<!-- dockerfiles -->/g, `${dockerText}`);
}

let readme = fs.readFileSync("./.github/templates.md", "utf8");

// <!-- gw-templates -->
readme = generateWorkflowFiles(readme);

// <!-- dockerfiles -->
readme = generateDockerFiles(readme);

fs.writeFileSync("./README.md", readme);
