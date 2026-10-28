import fs from 'node:fs/promises';
import path from 'node:path';
export async function runTrainerChecks({root,LuaFactory,wasmPath,sharedRoot,nexusRoot}) {
 const factory=new LuaFactory(wasmPath);
 async function mount(relative){for(const entry of await fs.readdir(path.join(root,relative),{withFileTypes:true})){
  const file=relative+'/'+entry.name;
  if(entry.isDirectory())await mount(file);else if(file.endsWith('.lua'))await factory.mountFile('/'+file,await fs.readFile(path.join(root,file),'utf8'));
 }}
 if(nexusRoot){
  await factory.mountFile('/Nexus1183/UEHelpers.lua',await fs.readFile(path.join(nexusRoot,'ue4ss/Mods/shared/UEHelpers/UEHelpers.lua'),'utf8'));
  await factory.mountFile('/Nexus1183/UE4SS-settings.ini',await fs.readFile(path.join(nexusRoot,'ue4ss/UE4SS-settings.ini'),'utf8'));
 }
 await mount('FFWTools');await factory.mountFile('/FFWTools/tests/Data/.keep','');
 if(sharedRoot){
  await factory.mountFile('/FFWTools/tests/overlay_mouse_engine.lua',await fs.readFile(path.join(sharedRoot,'FFWTools/tests/overlay_mouse_engine.lua'),'utf8'));
  for(const name of await fs.readdir(path.join(sharedRoot,'FFWTools/src/Common'))){
   if(name.endsWith('.lua'))await factory.mountFile('/FFWTools/src/Common/'+name,await fs.readFile(path.join(sharedRoot,'FFWTools/src/Common',name),'utf8'));
  }
 }

 const scripts=path.join(root,'FFWTools/src/FFWTrainer/Scripts');
 for(const install of ['/Install With Spaces','/中文 安装/测试游戏']){
  for(const name of await fs.readdir(scripts))if(name.endsWith('.lua'))await factory.mountFile(install+'/FarFarWest/Binaries/Win64/ue4ss/Mods/FFWTrainer/Scripts/'+name,await fs.readFile(path.join(scripts,name),'utf8'));
  await factory.mountFile(install+'/FarFarWest/Binaries/Win64/ue4ss/Mods/FFWTrainer/Data/.keep','');
 }
 const results=[];
 for(const name of (await fs.readdir(path.join(root,'FFWTools/tests'))).filter(n=>/(_test|_spec)\.lua$/.test(n))){
  const engine=await factory.createEngine();const output=[];engine.global.set('print',(...v)=>output.push(v.join(' ')));
  try{await engine.doString('local rename=os.rename;os.rename=function(a,b)local f=io.open(b,"rb");if f then f:close();return nil,"destination exists",17 end;return rename(a,b)end;os.exit=function(n)error("exit "..tostring(n))end;arg={[0]="FFWTools/tests/'+name+'"};dofile(arg[0])');results.push({name,passed:true,output});}
  catch(error){results.push({name,passed:false,error:error.message,output});}finally{engine.global.close();}
 }
 return {total:results.length,passed:results.filter(r=>r.passed).length,results};
}
