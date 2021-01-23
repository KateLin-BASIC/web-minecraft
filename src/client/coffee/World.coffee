
import pChunk from 'prismarine-chunk'
import vec3 from 'vec3'
import ndarray from "ndarray"


class World
	constructor:(noa)->
		_this=@
		@noa=noa
		@Chunk=pChunk "1.16.3"
		@chunkStorage={}
		@chunkNeedsUpdate={}
		@noa.world.on 'worldDataNeeded', (id, data, x, y, z)->
			noaChunk=_this.chunkStorage[id]
			noaNewChunk=new ndarray noaChunk.data,noaChunk.shape
			_this.noa.world.setChunkData id, noaNewChunk
			return
		@noa.world.on "playerEnteredChunk",(ci,cj,ck)->
			_this.loadChunksAroundPlayer ci,cj,ck
			_this.unloadChunksAroundPlayer ci,cj,ck
			return
		brownish = [0.45, 0.36, 0.22]
		@noa.registry.registerMaterial 'dirt', brownish, "dirt.png"
		@noa.registry.registerMaterial 'water',[0.5, 0.5, 0.8, 0.7], null
		@noa.registry.registerMaterial 'lava',[158/255, 83/255, 13/255,0.99], null

		@noa.registry.registerBlock 1, { material: 'dirt' }
		@noa.registry.registerBlock 2, { material: 'grass' }
		@noa.registry.registerBlock 3, { material: 'water' ,fluid:true}
		@noa.registry.registerBlock 4, { material: 'lava' ,fluid:true}
		return
	loadChunksAroundPlayer:(ci,cj,ck)->
		add = @noa.world.chunkAddDistance
		for i in [ci-add..ci+add]
			for j in [cj-add..cj+add]
				for k in [ck-add..ck+add]
					if not @noa.world._chunksKnown.includes(i, j, k)
						if @chunkStorage["#{i}|#{j}|#{k}|default"] isnt undefined
							@noa.world.manuallyLoadChunk i*16,j*16,k*16
		return
	unloadChunksAroundPlayer:(ci,cj,ck)->
		_this=@
		dist = @noa.world.chunkRemoveDistance
		@noa.world._chunksKnown.forEach (loc)->
			if _this.noa.world._chunksToRemove.includes(loc[0], loc[1], loc[2])
				return
			di = loc[0] - ci
			dj = loc[1] - cj
			dk = loc[2] - ck
			if dist <= Math.abs(di) or dist <= Math.abs(dj) or dist <= Math.abs(dk)
				_this.noa.world.manuallyUnloadChunk(loc[0] * 16, loc[1] * 16, loc[2] * 16)
			return
		return
	loadChunk:(chunk,x,z)->
		x=-x-1
		ch=@Chunk.fromJson chunk
		for y in [0..ch.sections.length-1]
			noaChunk=new ndarray new Uint16Array(16*16*16),[16, 16, 16]
			if ch.sections[y] isnt null
				for ix in [0..15]
					for iy in [0..15]
						for iz in [0..15]
							b=ch.getBlock vec3 ix,iy+y*16,iz
							if b.name is "air" or b.name is "cave_air" or b.name is "void_air"
								noaChunk.set 15-ix,iy,iz,0
							else if b.name is "water"
								noaChunk.set 15-ix,iy,iz,3
							else if b.name is "lava"
								noaChunk.set 15-ix,iy,iz,4
							else
								noaChunk.set 15-ix,iy,iz,1
			@chunkStorage["#{x}|#{y}|#{z}|default"]=noaChunk
			add = @noa.world.chunkAddDistance
			pos = @noa.ents.getPosition(@noa.playerEntity)
			ci = Math.ceil(pos[0] / 16)
			cj = Math.ceil(pos[1] / 16)
			ck = Math.ceil(pos[2] / 16)
			if x > ci - add && x < ci + add && y > cj - add && y < cj + add && z > ck - add && z < ck + add
				@noa.world.manuallyLoadChunk x*16,y*16,z*16
		return
export {World}