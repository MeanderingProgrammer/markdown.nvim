from pathlib import Path

from tree_sitter_languages import get_language, get_parser


def main() -> None:
    init_file: Path = Path("lua/render-markdown/init.lua")
    update_types(init_file)
    update_readme(init_file)


def update_types(init_file: Path) -> None:
    lines: list[str] = []
    for comment in get_comments(init_file):
        comment_type: str = comment.split()[0].split("@")[-1]
        if comment_type in ["class", "field"]:
            comment = comment.replace("User", "")
            if comment_type == "field":
                assert "?" in comment, f"All fields must be optional: {comment}"
                comment = comment.replace("?", "")
            if comment_type == "class" and len(lines) > 0:
                lines.append("")
            lines.append(comment)
    lines.append("")

    types_file: Path = Path("lua/render-markdown/types.lua")
    types_file.write_text("\n".join(lines))


def update_readme(init_file: Path) -> None:
    default_config = get_default_config(init_file)
    new_config = "require('render-markdown').setup(" + default_config + ")"

    readme_file = Path("README.md")
    current_config = get_readme_config(readme_file)

    text = readme_file.read_text()
    text = text.replace(current_config, new_config)
    readme_file.write_text(text)


def get_comments(file: Path) -> list[str]:
    query = "(comment) @comment"
    return ts_query(file, query, "comment")


def get_default_config(file: Path) -> str:
    query = """
        (variable_assignment(
            (variable_list(
                variable field: (identifier) @name
                (#eq? @name "default_config")
            ))
            (expression_list value: (table)) @value
        ))
    """
    default_configs = ts_query(file, query, "value")
    assert len(default_configs) == 1
    return default_configs[0]


def get_readme_config(file: Path) -> str:
    query = "(code_fence_content) @content"
    code_blocks = ts_query(file, query, "content")
    query_code_blocks = [code for code in code_blocks if "query" in code]
    assert len(query_code_blocks) == 1
    return query_code_blocks[0]


def ts_query(file: Path, query_string: str, target: str) -> list[str]:
    ts_language: str = {
        ".lua": "lua",
        ".md": "markdown",
    }[file.suffix]
    parser = get_parser(ts_language)
    tree = parser.parse(file.read_text().encode())

    language = get_language(ts_language)
    query = language.query(query_string)
    captures = query.captures(tree.root_node)

    values: list[str] = []
    for node, capture in captures:
        if capture == target:
            values.append(node.text.decode())
    return values


if __name__ == "__main__":
    main()
