const fs=require('node:fs');
const parser=require('luaparse');
const {spawnSync}=require('node:child_process');
const keys=new Set();
for(const name of ['Core','Main','View','EntryPoints','Tooltip','SpecialItems','UsageData']) {
  parser.parse(fs.readFileSync(`ItemLore/${name}.lua`,'utf8'),{luaVersion:'5.1',onCreateNode(n){
    if(n.type==='IndexExpression' && n.base.type==='Identifier' && n.base.name==='L') keys.add(n.index.raw);
  }});
}
const code=`GetLocale=function() return 'enUS' end; dofile('ItemLore/Locale.lua'); for _,key in ipairs({${[...keys].join(',')}}) do assert(not ItemLoreLocale[key]:find('[\\128-\\255]'), 'Missing English: '..key) end; print('PASS: ${keys.size} translated UI and usage strings')`;
const result=spawnSync(process.execPath,[require.resolve('fengari-node-cli/src/lua-cli.js'),'-e',`local ok,err=pcall(function() ${code} end); if not ok then io.stderr:write(err); os.exit(1) end`],{stdio:'inherit'});
if(result.error) throw result.error;
process.exit(result.status || 0);
