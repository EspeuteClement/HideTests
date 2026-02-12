{
	"type": "fx",
	"name": "BaseReference2",
	"x": 1.8,
	"y": 2.8,
	"duration": 500,
	"cullingRadius": 3,
	"children": [
		{
			"type": "emitter",
			"name": "emitter",
			"props": {
				"emitType": "Burst",
				"burstCount": 8,
				"burstParticleCount": 5,
				"maxCount": 44,
				"randomGradient": {
					"stops": [
						{
							"position": 0,
							"color": -16777216
						},
						{
							"position": 1,
							"color": -1
						}
					],
					"resolution": 64,
					"isVertical": false,
					"interpolation": "Linear",
					"colorMode": 0
				},
				"instSpeed": [
					1,
					0,
					0
				]
			},
			"children": [
				{
					"type": "material",
					"name": "material",
					"props": {
						"PBR": {
							"mode": "BeforeTonemapping",
							"blend": "Alpha",
							"shadows": false,
							"culling": "Back",
							"colorMask": 255
						}
					},
					"diffuseMap": "Textures/Gradient.png"
				}
			]
		}
	]
}