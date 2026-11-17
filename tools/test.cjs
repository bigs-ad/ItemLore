const fs = require('node:fs');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const parser = require('luaparse');
for (const file of fs.readdirSync('ItemLore').filter(f => f.endsWith('.lua'))) {
  parser.parse(fs.readFileSync(path.join('ItemLore', file), 'utf8'), { luaVersion: '5.1' });
}
const cli = require.resolve('fengari-node-cli/src/lua-cli.js');
for (const file of fs.readdirSync('ItemLore/tests').filter(f => f.endsWith('.test.lua'))) {
  const input = JSON.stringify(`ItemLore/tests/${file}`);
  const code = `local ok,err=pcall(dofile,${input}); if not ok then io.stderr:write(tostring(err),"\\n"); os.exit(1) end`;
  const result = spawnSync(process.execPath, [cli, '-e', code], { stdio: 'inherit' });
  if (result.error) throw result.error;
  if (result.status !== 0) process.exit(result.status || 1);
}
console.log('PASS: Lua 5.1 syntax and all mock tests');
