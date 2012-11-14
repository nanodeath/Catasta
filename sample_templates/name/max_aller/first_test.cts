---
parameters:
  page: int
  content: list of str
  map: map of str:str
  users: list of obj
---
<!doctype html>
<html>
  <head>
    <title></title>
  </head>
  <body>
    <div>
      {{= 1}}
      {{= "foo"}}
      <span>You are on page {{= page}}</span>
      <ul>
      {{for c in content}}
        {{if c}}
        <li>{{=c}}</li>
        {{/if}}
      {{/for}}
      </ul>
      {{for k, v in map}}
        <div>{{=k}}: {{=v}}</div>
      {{/for}}
      {{for key, v in map}}
        <div>{{=key}}</div>
      {{/for}}
      {{if page}}
        Page is not falsey (zero).
        Or is it?
        What if I nest if content in here?:
        {{if content}}
          Content is not falsey (empty).
        {{/if}}
      {{/if}}
      {{if content}}
        Content is not falsey (empty).
      {{/if}}
      {{if map}}
        Map is not falsey (empty).
      {{/if}}
      {{if users}}
        {{for o in users}}
        <div>{{= o.name}}</div>
        {{/for}}
      {{/if}}
    </div>
  </body>
</html>