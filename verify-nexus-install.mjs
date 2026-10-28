import fs from 'node:fs/promises';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
const hash=b=>createHash('sha256').update(b).digest('hex');
export async function verifyNexusContentArchive({archive,frameworkRoot,destination,JSZip}){
 await fs.mkdir(destination); // must be a new isolated directory
 const win64=path.join(destination,'FarFarWest/Binaries/Win64');await fs.mkdir(win64,{recursive:true});
 const protectedFiles=[];
 async function copy(relative=''){
  for(const entry of await fs.readdir(path.join(frameworkRoot,relative),{withFileTypes:true})){
   const rel=relative?relative+'/'+entry.name:entry.name;
   if(entry.isDirectory()){await fs.mkdir(path.join(win64,rel),{recursive:true});await copy(rel);}
   else{const data=await fs.readFile(path.join(frameworkRoot,rel));await fs.writeFile(path.join(win64,rel),data);protectedFiles.push({rel,sha256:hash(data)});}
  }
 }
 await copy();
 const dataPath=path.join(win64,'ue4ss/Mods/FFWTrainer/Data/settings.json');await fs.mkdir(path.dirname(dataPath),{recursive:true});await fs.writeFile(dataPath,'{"unlimited":true,"spawnMode":"direct","fixture":true}');const dataHash=hash(await fs.readFile(dataPath));
 const zip=await JSZip.loadAsync(await fs.readFile(archive),{checkCRC32:true});let files=0;
 for(const item of Object.values(zip.files)){
  if(item.dir||!item.name.startsWith('GameRoot/'))continue;
  const rel=item.name.slice('GameRoot/'.length);
  assert.ok(rel.startsWith('FarFarWest/Binaries/Win64/ue4ss/Mods/FFWTrainer/'),'content ZIP must not overwrite Nexus framework files');
  assert.ok(!rel.split(/[\\/]/).includes('..')&&!/^(?:[A-Za-z]:|\/)/.test(rel),'unsafe archive path');
  assert.ok(!rel.includes('/Data/'),'content ZIP must preserve player Data');
  const target=path.join(destination,rel);await fs.mkdir(path.dirname(target),{recursive:true});await fs.writeFile(target,await item.async('nodebuffer'));files++;
 }
 for(const f of protectedFiles)assert.equal(hash(await fs.readFile(path.join(win64,f.rel))),f.sha256,'framework changed: '+f.rel);
 assert.equal(hash(await fs.readFile(dataPath)),dataHash,'Data changed');
 await fs.access(path.join(win64,'ue4ss/Mods/FFWTrainer/Scripts/main.lua'));
 return {contentRuntimeFiles:files,frameworkFilesPreserved:protectedFiles.length,playerDataPreserved:true};
}
