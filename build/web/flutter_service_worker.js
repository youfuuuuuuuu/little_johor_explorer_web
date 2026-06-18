'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "4ad9c1dce38a842f0d17ce1739e1bb55",
"assets/AssetManifest.bin.json": "91ef3e1e9377560083f2703df88e2332",
"assets/assets/images/avatars/capybara.png": "9e48ec26567ad0dc6469363a959dc3b9",
"assets/assets/images/avatars/greater_flamingo.png": "eb195c1a20e50379f0fba829f2c633f0",
"assets/assets/images/avatars/malayan_tapir.png": "e1d82a5294752cd1348bc695871e0e63",
"assets/assets/images/avatars/malayan_tiger.png": "eb95a24f9b1ae3cb34b2ff6834eaa9ea",
"assets/assets/images/avatars/mandrill.png": "f89e55b020021bece18771dbca96ad26",
"assets/assets/images/avatars/saltwater_crocodile.png": "4831aab1a298f6062cd1b89814b5e4bf",
"assets/assets/images/avatars/sun_bear.png": "a901578f9fb67e28e34935672bda82fb",
"assets/assets/images/avatars/wallaby.png": "4fc56db3fa6cf11c83bf959bee26bc83",
"assets/assets/images/chingay/batch_1781751589.zip": "d8fc6680ac3c6482ac30d3ede69c8c09",
"assets/assets/images/chingay/c1.png": "644a186dc00fe59b47fd67da2bfaaf0b",
"assets/assets/images/chingay/c1.webp": "b9245eea1cc799ea5eb9f7179b780079",
"assets/assets/images/chingay/c2.png": "df3a9a67f6198c2c74fbc9993cff713c",
"assets/assets/images/chingay/c2.webp": "317e751d8b5c66b311ef1e3e2e62af37",
"assets/assets/images/chingay/c3.png": "8d0db7ce3bb3e42403272694ba742749",
"assets/assets/images/chingay/c3.webp": "be14a3b241232d6b54386469456c54c4",
"assets/assets/images/chingay/c4.png": "af64cc0ca879c45e73e318bf85f4980f",
"assets/assets/images/chingay/c4.webp": "c7262d790aa37963e525776ab7ae32e4",
"assets/assets/images/chingay/c5.png": "d0aef7e1c9e4802a23bfd98940848768",
"assets/assets/images/chingay/c5.webp": "4ca888b494199778a7e43d58b525d699",
"assets/assets/images/chingay/c6.png": "d5fe66c5424bd0154d8495b24707304c",
"assets/assets/images/chingay/c6.webp": "3725905f7e1e68fad6845330b78ac05c",
"assets/assets/images/chingay/c7.png": "4abc6d8e3f5681b31b878ac39f39ced3",
"assets/assets/images/chingay/c7.webp": "24d5c375464c7ed14794c0f81c9c9f80",
"assets/assets/images/chingay/c8.png": "b0dcf1cc822f97c1df36220ce0bb05aa",
"assets/assets/images/chingay/c8.webp": "09d476faf728a80826f94f144b0ea0a3",
"assets/assets/images/johor/johor_1.png": "049e1f0a01ac86762b36a002d06db79c",
"assets/assets/images/johor/johor_1.webp": "dc78c69f56a9c0d8d8a85f3d4def846b",
"assets/assets/images/johor/johor_10.png": "73b393d89404817a2e23a040826a8d0e",
"assets/assets/images/johor/johor_10.webp": "d3da658c3fe1f2b1a29d03106b878615",
"assets/assets/images/johor/johor_10c.png": "d7b306364cd32949715a459832d54565",
"assets/assets/images/johor/johor_10c.webp": "dcbcd44061b316c15c9664a29ea4267c",
"assets/assets/images/johor/johor_11.png": "4e71a5b4eab383ec92220a4628c51392",
"assets/assets/images/johor/johor_11.webp": "755cb16a1f487a2684abfa8a2b3d73c3",
"assets/assets/images/johor/johor_12.png": "a48b3608da581035cdf2790f1476131b",
"assets/assets/images/johor/johor_12.webp": "d79bb9922b4437bf89a2c9587ac7fa92",
"assets/assets/images/johor/johor_13.png": "6336175c00c4ea7f89d26c7af736a746",
"assets/assets/images/johor/johor_13.webp": "76d89d5506276834001106156a1ac14b",
"assets/assets/images/johor/johor_14.png": "fed52006bdb8426329f92e5d0b42818b",
"assets/assets/images/johor/johor_14.webp": "587b6c695e827a98eadc572b78a69222",
"assets/assets/images/johor/johor_15.png": "77326d8661b19a9b4cdf90d501b9e4b8",
"assets/assets/images/johor/johor_15.webp": "fcff0e11aecbe7d0fc0dd762cbe9d135",
"assets/assets/images/johor/johor_2.png": "8da15560a937d013c4c311a765badf44",
"assets/assets/images/johor/johor_2.webp": "7a35df4856d073fd77cd997d0e72d70e",
"assets/assets/images/johor/johor_2c.png": "7fbefd70977996d33f976cbb0d89b631",
"assets/assets/images/johor/johor_2c.webp": "81b035c3e0fa28acf6f76f8ace2e4287",
"assets/assets/images/johor/johor_3.png": "697606424df66dfa4842a7d091ff92ae",
"assets/assets/images/johor/johor_3.webp": "6f1770927357f83285db67b2cf583773",
"assets/assets/images/johor/johor_3c.png": "2a2acb35ab59a35c7c30ae9166cf35c1",
"assets/assets/images/johor/johor_3c.webp": "f764217456ed571c14044d9cd08e57de",
"assets/assets/images/johor/johor_4.png": "c00538195a2165fab75eb9ccf74d4bc7",
"assets/assets/images/johor/johor_4.webp": "7b4241482f0b67484e593224c80971b8",
"assets/assets/images/johor/johor_5.png": "c13a71906e38f3bcc912d6b969ca8be0",
"assets/assets/images/johor/johor_5.webp": "f0b1a18483ca382a60941b1620552f38",
"assets/assets/images/johor/johor_5c.png": "7c3a6420608b4a37ca69dec63a3be44e",
"assets/assets/images/johor/johor_5c.webp": "0a6b700b858e303a738e848d6dad0ab3",
"assets/assets/images/johor/johor_6.png": "b4ff0b6be2ff9936ac593e2ccb684104",
"assets/assets/images/johor/johor_6.webp": "ba93bd26d67d38e5d99fd13200d16590",
"assets/assets/images/johor/johor_7.png": "a6873efeea9dfdd9a3945f340d204541",
"assets/assets/images/johor/johor_7.webp": "39bac6e0d8cc956cb837baca15d602bf",
"assets/assets/images/johor/johor_7c.png": "09f46e2fd80708367905fb8a2bf3fab8",
"assets/assets/images/johor/johor_7c.webp": "a56d37391a119b067f3fecfb6df71422",
"assets/assets/images/johor/johor_8.png": "78e857e8600a481253f62fc08608a11c",
"assets/assets/images/johor/johor_8.webp": "eae157bf69b45b79a6edd6989ad445f4",
"assets/assets/images/johor/johor_9.png": "3b1822da6631d4df8fa7bd5329bf9154",
"assets/assets/images/johor/johor_9.webp": "74e2bb250e92c53e162b5686b7b5654a",
"assets/assets/images/kota_jail/kj_1.png": "b2fe00c45a723a421caa98bea1fe14f4",
"assets/assets/images/kota_jail/kj_1.webp": "1cbbca689e3d46c58746c9d88dd7b53d",
"assets/assets/images/kota_jail/kj_2.png": "329324c06f0ce383c96be028c846b18a",
"assets/assets/images/kota_jail/kj_2.webp": "f09540624a33800239142c7a29a0bb1b",
"assets/assets/images/kota_jail/kj_3.png": "359dd4192d4e35d0465627a261249167",
"assets/assets/images/kota_jail/kj_3.webp": "335c89c2cf3daad6817bfe916d2eccfa",
"assets/assets/images/kota_jail/kj_4.png": "a853d06f101aaf8548be013f99d6ffc3",
"assets/assets/images/kota_jail/kj_4.webp": "970986d98e483036519ce19102db641e",
"assets/assets/images/kota_jail/kj_5.png": "45a7a01d79cbbf3082bce6800ef17ab8",
"assets/assets/images/kota_jail/kj_5.webp": "653f4933f7721adb0afd0d416fdfd00b",
"assets/assets/images/kota_jail/kj_6.png": "21c4346b7332d3803f229d93a596e9f3",
"assets/assets/images/kota_jail/kj_6.webp": "97553d4df28311b64b59ef47f672e36d",
"assets/assets/images/kota_jail/kj_7.png": "22f0055e3e6db9a1909b934525733a70",
"assets/assets/images/kota_jail/kj_7.webp": "530c8574873ae27920b86738b2df804f",
"assets/assets/images/kota_jail/kj_8.png": "848063b1e18aa7f798b06344632b8359",
"assets/assets/images/kota_jail/kj_8.webp": "51557987a8bccc35bc80afddc64bc571",
"assets/assets/images/kota_jail/kj_9.png": "1d11e31309c0eb74b578e9709a6c988d",
"assets/assets/images/kota_jail/kj_9.webp": "c6472bde7b4c201ce624128c36dfbca4",
"assets/assets/images/marteen_ke_johor_bahru/jb_1.png": "c1918e7572aa93a1f2a2ef0d7397612e",
"assets/assets/images/marteen_ke_johor_bahru/jb_1.webp": "38b47842618d320a57a97e1657372c0b",
"assets/assets/images/marteen_ke_johor_bahru/jb_2.png": "4efac8f5282d4755fcecfac35a049165",
"assets/assets/images/marteen_ke_johor_bahru/jb_2.webp": "d31ed43808559ad5c9b64a68fe9dd2f2",
"assets/assets/images/marteen_ke_johor_bahru/jb_3.png": "7c872fd9ef17dbc91b30b74eeb03d5ac",
"assets/assets/images/marteen_ke_johor_bahru/jb_3.webp": "cafda9ef1caa5ebec7d0990a08478bb8",
"assets/assets/images/marteen_ke_johor_bahru/jb_4.png": "8911be7f6f4e8bcbef4eeb1b2ec1b9d6",
"assets/assets/images/marteen_ke_johor_bahru/jb_4.webp": "4ca6dd8ddc47f6813f3c29c29a851d6c",
"assets/assets/images/marteen_ke_johor_bahru/jb_5.png": "6343c1c23b1fde6b2e01ae5c56015d13",
"assets/assets/images/marteen_ke_johor_bahru/jb_5.webp": "a1d047432b741e7a45254073a059b1f8",
"assets/assets/images/marteen_ke_johor_bahru/jb_6.png": "556e14733ff64f69da7571e0d19f2d67",
"assets/assets/images/marteen_ke_johor_bahru/jb_6.webp": "25e9ef003ccb2c3eee2b42465d20b4c6",
"assets/assets/images/marteen_ke_johor_bahru/jb_7.png": "1de38727d98a29883f4da004214381e6",
"assets/assets/images/marteen_ke_johor_bahru/jb_7.webp": "e70ae80aa0411f0695ab7a10660da24c",
"assets/assets/images/marteen_ke_johor_bahru/jb_8.png": "15cfe565c7f099034e51d8db8077393f",
"assets/assets/images/marteen_ke_johor_bahru/jb_8.webp": "bfa6de3a91bed153b0575aa90467b6a5",
"assets/assets/images/marteen_ke_johor_bahru/jb_9.png": "b02aa80e678911e739a821b7349243c5",
"assets/assets/images/marteen_ke_johor_bahru/jb_9.webp": "bbece71af452f6e6e99cbc14a9d4a124",
"assets/assets/images/marteen_ke_kota_tinggi/kt_1.png": "ffaf1a59a551eb159668bb2b540ca816",
"assets/assets/images/marteen_ke_kota_tinggi/kt_1.webp": "0d511a66430c4d5c9a8af59d317fbe81",
"assets/assets/images/marteen_ke_kota_tinggi/kt_2.png": "197d26313ee94734a1b3ee290b110303",
"assets/assets/images/marteen_ke_kota_tinggi/kt_2.webp": "18031e6fd9be4ed4f4aa4c046253f7e5",
"assets/assets/images/marteen_ke_kota_tinggi/kt_3.png": "2b71e4c347f059c3a0569e85ec9a6355",
"assets/assets/images/marteen_ke_kota_tinggi/kt_3.webp": "3c3ea171656af2b09e4ebc5e1be23b28",
"assets/assets/images/marteen_ke_kota_tinggi/kt_4.png": "6eb0770191cbeca334f2d61a5ca3ac6e",
"assets/assets/images/marteen_ke_kota_tinggi/kt_4.webp": "d067d040451d0a448945abd06e09d860",
"assets/assets/images/marteen_ke_kota_tinggi/kt_5.png": "009ab756640518c68b8e7079ec0fba8c",
"assets/assets/images/marteen_ke_kota_tinggi/kt_5.webp": "cea5e9633722daf3549ea6cdceda0d63",
"assets/assets/images/marteen_ke_kota_tinggi/kt_6.png": "f3a5733326aed09b0941a35f5f4dd834",
"assets/assets/images/marteen_ke_kota_tinggi/kt_6.webp": "6dff24dd8308e016eaacdd0e7c782f08",
"assets/assets/images/marteen_ke_kota_tinggi/kt_7.png": "c4dd6b9ca60cd747f22cb41bdea683a6",
"assets/assets/images/marteen_ke_kota_tinggi/kt_7.webp": "983f72befadcd0f05c063461110dd722",
"assets/assets/images/marteen_ke_kota_tinggi/kt_8.png": "30a40fedcb50d11dd017c80842c836d6",
"assets/assets/images/marteen_ke_kota_tinggi/kt_8.webp": "a859a0f1dc4ee1e024f03786287c3796",
"assets/assets/images/marteen_ke_kota_tinggi/kt_9.png": "5cf246a985de61f079edf0c4e6b8e5f3",
"assets/assets/images/marteen_ke_kota_tinggi/kt_9.webp": "805d697f59ba7db7b3138c648b30a8aa",
"assets/assets/images/marteen_ke_muar/muar_1.png": "4a461574a3dc9d9bd42ee636d4c2a89e",
"assets/assets/images/marteen_ke_muar/muar_1.webp": "eaa4151f756a6e3410e6683b9f3afab7",
"assets/assets/images/marteen_ke_muar/muar_2.png": "95c3caae13b1765c889c59664101c49d",
"assets/assets/images/marteen_ke_muar/muar_2.webp": "e32fd6941b6768fc9164de79abcce3c7",
"assets/assets/images/marteen_ke_muar/muar_3.png": "2072afee30261b3783f83703442e1222",
"assets/assets/images/marteen_ke_muar/muar_3.webp": "29bbb110f37ade3792b5eb91a9afbb82",
"assets/assets/images/marteen_ke_muar/muar_4.png": "9614dadafc25becad0c15f2c501d6559",
"assets/assets/images/marteen_ke_muar/muar_4.webp": "41f53e9aa5d1e3f65e89540218eeae83",
"assets/assets/images/marteen_ke_muar/muar_5.png": "723207e394022530aa9f55b278d1d556",
"assets/assets/images/marteen_ke_muar/muar_5.webp": "18d112b1a7388b979e9ab013da9a22a5",
"assets/assets/images/marteen_ke_muar/muar_6.png": "5ef36b1ead65485856493c2bee2b5aa8",
"assets/assets/images/marteen_ke_muar/muar_6.webp": "cf8e9ff1bb4d66ef996d0201970620dd",
"assets/assets/images/marteen_ke_muar/muar_7.png": "1f2dbc76329f1ddfb6b982941e2db779",
"assets/assets/images/marteen_ke_muar/muar_7.webp": "e8fed9ee7d5aa03ae619d1eb4303c2e3",
"assets/assets/images/marteen_ke_muar/muar_8.png": "507359d1b47cb75394db5ddca2706139",
"assets/assets/images/marteen_ke_muar/muar_8.webp": "3f542470b4f297ac93c61775c03f0394",
"assets/assets/images/marteen_ke_muar/muar_9.png": "a6622a089de01e12e2d705ea67d1203d",
"assets/assets/images/marteen_ke_muar/muar_9.webp": "c7a1c331cabdb622060dc84e153cf699",
"assets/assets/images/masjid/m1.png": "b7078863d8a04d1ea9357d6492e083d4",
"assets/assets/images/masjid/m1.webp": "3083b2797500785daeb0c5609a645dbf",
"assets/assets/images/masjid/m2.png": "0ba2328615c81fc37f586ea01e875fc7",
"assets/assets/images/masjid/m2.webp": "4c99997b338663e1b57f394b33d97f43",
"assets/assets/images/masjid/m3.png": "bfe4f7c2164bde2c798ae7ee182aac33",
"assets/assets/images/masjid/m3.webp": "0f218f844903e15b9d9c0253c4edc733",
"assets/assets/images/masjid/m4.png": "c70ac15a2a51cfcfededc7c3da66ce72",
"assets/assets/images/masjid/m4.webp": "75962e3a1e51a31597145a86c718735f",
"assets/assets/images/masjid/m5.png": "cb7b4df0329c3522e4206403c57c3aac",
"assets/assets/images/masjid/m5.webp": "cfa6a00c8d3af49305fff2f21f29e3d6",
"assets/assets/images/masjid/m6.png": "0e29c7c7bcb51bb863d8c75cd403a120",
"assets/assets/images/masjid/m6.webp": "0ef7372851734a44ebd90b9c26de6611",
"assets/assets/images/masjid/m7.png": "2b69ab27edffa6534b9fc58a38315c51",
"assets/assets/images/masjid/m7.webp": "c4f0aec8a71506e750fb368e3fbb6a59",
"assets/assets/images/masjid/m8.png": "36daa93f8add0481ab70cfa7eb73b81a",
"assets/assets/images/masjid/m8.webp": "1abcf02c4ac9108483c953e1765a4fee",
"assets/assets/images/masjid/m9.png": "d0709afed6207f59b1eb0a85298dbfc6",
"assets/assets/images/masjid/m9.webp": "dc7e8383826dc99378d80bdde213a78f",
"assets/assets/images/sultan_abu_bakar/sab_1.png": "4075ffb946fad0bf6ae02839810d12ff",
"assets/assets/images/sultan_abu_bakar/sab_1.webp": "215498949b66dc5f739847a7d1c1cba8",
"assets/assets/images/sultan_abu_bakar/sab_2.png": "703b9411f7d577207b10c3d9fffdeb3d",
"assets/assets/images/sultan_abu_bakar/sab_2.webp": "79b753cc2def6e67e07f53a73420d6e6",
"assets/assets/images/sultan_abu_bakar/sab_3.png": "7c7b6dbbe7fd4123576bb504c74972cf",
"assets/assets/images/sultan_abu_bakar/sab_3.webp": "71f78766ad45a3c3e1d356b65f4d64af",
"assets/assets/images/sultan_abu_bakar/sab_4.png": "216240d4e78ae905ab4bae39026d74cc",
"assets/assets/images/sultan_abu_bakar/sab_4.webp": "2e7ed5388efffef414b5f02c6d540d1d",
"assets/assets/images/sultan_abu_bakar/sab_5.png": "df87b25d22d980a3874a00f4480c30c7",
"assets/assets/images/sultan_abu_bakar/sab_5.webp": "034dc1494ab9d57e9f521a81d89b2fda",
"assets/assets/images/sultan_abu_bakar/sab_6.png": "e4e25103be9c5a46fddffe4e8d72e628",
"assets/assets/images/sultan_abu_bakar/sab_6.webp": "9065624c50a9f0bcc3c5b34ac8ccb2c3",
"assets/assets/images/sultan_abu_bakar/sab_7.png": "39d6cd6e7b1ba76d2f7dfcf05a7dd751",
"assets/assets/images/sultan_abu_bakar/sab_7.webp": "2a6a480096e04eda71fa22654f9b9722",
"assets/assets/images/sultan_abu_bakar/sab_8.png": "2da4f5598de4805bf717965985584eca",
"assets/assets/images/sultan_abu_bakar/sab_8.webp": "ad36a48aa26b584cfe243ff1056a2191",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/fonts/MaterialIcons-Regular.otf": "9950037a7fbd87f043f44fbeb30da507",
"assets/NOTICES": "a7f219ebb7dd433181ebb6f94d2f2c23",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/packages/record_web/assets/js/record.fixwebmduration.js": "1f0108ea80c8951ba702ced40cf8cdce",
"assets/packages/record_web/assets/js/record.worklet.js": "6d247986689d283b7e45ccdf7214c2ff",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"canvaskit/canvaskit.js": "8331fe38e66b3a898c4f37648aaf7ee2",
"canvaskit/canvaskit.js.symbols": "a3c9f77715b642d0437d9c275caba91e",
"canvaskit/canvaskit.wasm": "9b6a7830bf26959b200594729d73538e",
"canvaskit/chromium/canvaskit.js": "a80c765aaa8af8645c9fb1aae53f9abf",
"canvaskit/chromium/canvaskit.js.symbols": "e2d09f0e434bc118bf67dae526737d07",
"canvaskit/chromium/canvaskit.wasm": "a726e3f75a84fcdf495a15817c63a35d",
"canvaskit/skwasm.js": "8060d46e9a4901ca9991edd3a26be4f0",
"canvaskit/skwasm.js.symbols": "3a4aadf4e8141f284bd524976b1d6bdc",
"canvaskit/skwasm.wasm": "7e5f3afdd3b0747a1fd4517cea239898",
"canvaskit/skwasm_heavy.js": "740d43a6b8240ef9e23eed8c48840da4",
"canvaskit/skwasm_heavy.js.symbols": "0755b4fb399918388d71b59ad390b055",
"canvaskit/skwasm_heavy.wasm": "b0be7910760d205ea4e011458df6ee01",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "24bc71911b75b5f8135c949e27a2984e",
"flutter_bootstrap.js": "175f846dc53943ec5638ada01c026e62",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "121100a1d99df08df0c0a68bf43022f1",
"/": "121100a1d99df08df0c0a68bf43022f1",
"logo.PNG": "12424bb29631c43c53ed29f7ba3f10f1",
"main.dart.js": "660a136e50f791ad681294e04ef7c98f",
"manifest.json": "a54b6b171c919f7d00800ddae5b648c0",
"splash/img/dark-1x.png": "5b508038e332c9c416d05a92f1dde92a",
"splash/img/dark-2x.png": "a0697b24325d464d98699a57b219b58f",
"splash/img/dark-3x.png": "28a640f921af090179d26e62374e5e8b",
"splash/img/dark-4x.png": "f0b47d0f997927fffafdddddacff7bcd",
"splash/img/light-1x.png": "5b508038e332c9c416d05a92f1dde92a",
"splash/img/light-2x.png": "a0697b24325d464d98699a57b219b58f",
"splash/img/light-3x.png": "28a640f921af090179d26e62374e5e8b",
"splash/img/light-4x.png": "f0b47d0f997927fffafdddddacff7bcd",
"version.json": "ff908ad509154d96858c4a104812b7a9"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
