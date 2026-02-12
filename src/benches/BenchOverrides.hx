package benches;

class BenchOverrides extends hxd.App {
	final numSamples = 100_000;

	var benches : Array<{name: String, time: Float}> = [];

	function runBench(name: String, cb: () -> Void) {
		var start = haxe.Timer.stamp();

		cb();

		var end = haxe.Timer.stamp();

		benches.push({name: name, time: end - start});
	}

	override function init() {
		super.init();


		{
			var root = new h3d.scene.Object(s3d);

			hl.Profile.event(0);

			runBench("Load override",
			() -> {
				for (i in 0...numSamples) {
					hxd.Res.Tests.Overrides.BenchPerfOverride.load().make(root);
				}
			});

			root.remove();
		}

		{
			var root = new h3d.scene.Object(s3d);
			hl.Profile.event(0);

			runBench("Base", () -> {
				for (i in 0...numSamples) {
					hxd.Res.Tests.Overrides.BaseReference.load().make(root);
				}
			});

			root.remove();
		}


		{

			var root = new h3d.scene.Object(s3d);

			hl.Profile.event(0);
			runBench("Load reference",
			() -> {
				for (i in 0...numSamples) {
					hxd.Res.Tests.Overrides.BenchPerfBase.load().make(root);
				}
			});

			root.remove();
		}

		hl.Profile.event(0);

		for (i => run in benches) {
			if (i == 0) {
				trace('${run.name} : ${run.time}s');
			} else {
				var base = benches[0].time;
				var delta = (run.time / base - 1.0) * 100.0;
				trace('${run.name} : ${run.time}s ($delta % from Base)');
			}
		}

	}

	static function main() {
		hxd.Res.initLocal();
      new BenchOverrides();
    }
}