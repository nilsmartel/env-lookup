# env-lookup

cli tool to be used along with `string template` in order to easily access environment variables in templates like this:

```yaml
name: {{NAME}}
version: {{VERSION}}
```

string: https://github.com/nilsmartel/string

the tool itself reads the name of a variable from stdin and places the value into stdout:


```sh
echo "PATH" | env-lookup
```

You can read envs from env files. Multiple ones even
```sh
echo "PATH" | env-lookup -e .env my-other-env-file
```
