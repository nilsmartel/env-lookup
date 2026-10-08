# env-lookup

cli tool to be used along with `string template` in order to easily access environment variables in templates like this:

```yaml
name: {{NAME}}
version: {{VERSION}}
```

string: https://github.com/nilsmartel/string

the tool itself reads the name of a variable from stdin (default) or as first argument and writes the value into stdout:


```sh
echo PATH | env-lookup
env-lookup PATH
```

You can read envs from env files. Multiple ones even
`.env` files can be given with `-e` or `--env` (looked up before the environment):

```sh
env-lookup HELLO -e sample-env
echo "PATH" | env-lookup -e .env my-other-env-file
```

> Note: `-e` accepts multiple files, so put the variable name before it (or after a `--`).
