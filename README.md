# eval-env

cli tool to be used along with `string template` in order to easily access environment variables in templates like this:

```yaml
name: {{NAME}}
version: {{VERSION}}
```

string: https://github.com/nilsmartel/string

the tool itself reads the name of a variable from stdin and places the value into stdout:


```sh
echo "PATH" | eval-env
```

