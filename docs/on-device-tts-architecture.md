# On-device TTS architecture

Issue: [#244](https://github.com/takoikatakotako/charalarm/issues/244)

> **Status (2026-10-10):** 優先度を下げた。5.0.0 の新キャラの声は Gemini TTS の Voice Replication で実装する（[#245](https://github.com/takoikatakotako/charalarm/issues/245)）。この文書は調査記録として残す。

権利関係と配布時の判断記録は、[TTSの権利・ライセンス判断メモ](development/tts-rights-and-licensing.md)を参照。

## Decision

Use a versioned Voice Pack boundary and keep the application-facing TTS API independent from a specific engine.

Style-Bert-VITS2 is the selected product-development pipeline for custom voices. The first production candidate is trained only from the project owner's recordings. Voice actor recordings and contracts are a later phase, after voice quality and mobile performance have been demonstrated with the owner voice.

The first Style-Bert-VITS2 proof of concept should use ONNX Runtime as the common iOS/Android runtime. On iOS, establish a CPU/XNNPACK baseline first and then benchmark the same ONNX graph with the Core ML Execution Provider. Do not make a separate `.mlmodel` conversion a prerequisite for the first PoC.

VOICEVOX Core remains in the project as the working Japanese baseline until Style-Bert-VITS2 meets the quality, latency, size, memory, power, and licensing gates.

The product boundary is deliberate:

```text
Training workspace (AGPL-aware, published)
  recordings -> Style-Bert-VITS2 -> ONNX export -> signed Voice Pack

Distribution service
  catalog -> entitlement check -> immutable Voice Pack download

Charalarm app
  permissive mobile runtime -> installed Voice Pack -> offline synthesis
```

Do not embed the Style-Bert-VITS2 Python application in Charalarm. The mobile app consumes exported data through a documented Voice Pack contract and uses an independently maintained ONNX runtime and frontend.

## Important finding

A Style-Bert-VITS2 character is not a self-contained `Alice.onnx` file. Synthesis also requires text normalization, language-specific phoneme and accent generation, BERT features, style vectors, model configuration, and waveform encoding/playback.

Separate the system into these layers:

```text
Application
  -> TextToSpeechRepository
      -> Text processor (language-specific)
      -> Acoustic model runtime (engine-specific)
      -> PCM/WAV encoder
  -> VoicePackStore
      -> manifest validation
      -> integrity/version checks
      -> shared language assets
      -> character model and styles
```

Large language assets should be shareable by multiple characters. Repeating the Japanese BERT model and dictionary in every paid character pack would waste storage and complicate updates.

## Voice Pack v1

`VoicePackManifest` defines the initial contract. A downloadable pack is a directory or archive containing `manifest.json` and the declared assets.

```text
Alice-ja/
├── manifest.json
├── model/
│   ├── model.onnx
│   └── style_vectors.npy
└── language/                  # omit when using installed shared assets
    └── ja/
        ├── bert.onnx
        └── dictionary.bin
```

Every asset has a relative path, byte size, and SHA-256 digest. Packs must be extracted into a staging directory, validated, and atomically promoted. Absolute paths and `..` traversal are rejected. A later distribution layer should add a signed catalog or signed manifest; hashes alone detect corruption but do not establish publisher authenticity.

The production manifest must additionally record provenance and compatibility:

- pack and model semantic versions
- minimum TTS runtime version
- Style-Bert-VITS2 repository commit and export tool version
- base checkpoint identifier and license
- recording owner or contracted performer identifier
- dataset consent record identifier (not the private contract itself)
- licenses and attribution file paths
- model input/output schema and required ONNX opset
- shared language asset version
- signing key identifier

Voice Packs are immutable. Updating a voice creates a new pack version so alarms can keep using the last validated local version and roll back safely.

## Product and subscription boundary

The subscription sells ongoing Charalarm value, not exclusive ownership of model weights.

```text
StoreKit subscription
  -> EntitlementRepository
      -> VoiceCatalog access
      -> cloud sync / backup
      -> premium alarm and style features

VoicePackStore
  -> downloads while entitled
  -> validates signature and hashes
  -> installs atomically
  -> continues fully offline after installation
```

Use StoreKit for digital feature and content access. Keep subscription receipt handling outside the TTS engine. Synthesis must never make a network call; entitlement is checked when browsing or downloading a pack, not on every alarm. Product policy must explicitly decide what happens to already installed packs after a subscription expires. The initial recommendation is to keep at least the last selected voice usable for existing alarms, avoiding an alarm failure caused by billing or connectivity.

Do not rely on model encryption or anti-extraction as the business model. Signing protects authenticity; hashes protect integrity. License terms, service convenience, updates, cloud features, and official support provide the commercial value.

## Distribution and license boundary

For the first release:

- Charalarm source remains publicly available.
- Style-Bert-VITS2 training and export modifications are published with the exact source used to produce shipped models.
- The iOS/Android app does not include Style-Bert-VITS2 Python source or runtime.
- Exported Style-Bert-VITS2 models are conservatively treated as AGPL-covered unless a different written permission is obtained.
- Every Voice Pack includes its model card, license, notices, and a source/export-recipe URL.
- Optional Voice Packs should be delivered from the Charalarm distribution service rather than embedded in the App Store binary.
- User terms must not prohibit rights granted by the open-source licenses for covered components.

This is an engineering compliance policy, not a definitive legal conclusion. Record every upstream commit, asset URL, checksum, and license at acquisition time so a questionable dependency can be replaced without reconstructing history.

## Recording phases

### Phase 1: owner voice

- Use only recordings made specifically by the project owner.
- Use original or clearly licensed scripts.
- Do not merge JVNV, Amitaro, or another character/speaker model.
- Train 15, 30, 60, and 120 minute checkpoints first; expand the corpus only after listening tests identify the limiting defects.
- Keep raw recordings and transcripts private; publish tooling and provenance, not private source audio by default.

### Phase 2: voice actors

Start only after Phase 1 passes the product gates. A performer agreement must explicitly cover:

- machine-learning training and synthetic speech generation
- commercial app and subscription use, territories, media, and term
- distribution of model weights to user devices and the applicable model license
- compensation, credit, name/character usage, and permitted content
- retraining, style additions, model updates, and business transfer
- security incidents, contract termination, and already-installed copies
- dataset retention/deletion and whether source recordings may be reused

The performer must understand that an open-source model license may permit downstream model redistribution. Do not promise technical exclusivity that the selected license cannot enforce.

## Runtime comparison plan

Run identical phrases on a physical device and record:

- cold model load latency
- warm synthesis latency
- Real-Time Factor (`synthesis seconds / generated audio seconds`)
- peak resident memory
- installed runtime size and complete language/voice asset size
- energy and thermal behavior over repeated synthesis
- waveform parity or perceptual regressions between providers

Start with the default CPU provider for correctness. Test XNNPACK next. Test Core ML only after checking graph compatibility; unsupported operators or dynamic shapes can split the graph and make it slower. Enable the Core ML model cache for repeat launches if compilation time is significant.

Suggested acceptance targets for the PoC (product targets, not upstream guarantees):

- warm RTF below 1.0 on the oldest supported iPhone
- cold first utterance below 3 seconds
- peak additional memory below 500 MB
- one Japanese voice plus shared language assets below 500 MB after optimization
- no network access during initialization or synthesis

## Training experiment

The upstream project requires multiple transcribed clips of roughly 2–14 seconds but does not prescribe a universal total duration. Quality depends more on clean, consistent recording, phonetic coverage, transcription accuracy, and style balance than on duration alone.

Record one controlled corpus and train checkpoints at cumulative durations of 15, 30, 60, and 120 minutes. Evaluate each with the same unseen script and device pipeline. Treat 60 minutes as the planning baseline until listening tests show that less data is sufficient.

Voice actor recording is intentionally deferred until the owner-voice PoC proves this pipeline. The later commercial recording agreement must explicitly cover training, generated audio, redistribution of model weights, subscription distribution, updates, and termination/removal handling.

## Licensing policy

Style-Bert-VITS2 source is AGPL-3.0, with its `text/user_dict` module under LGPL-3.0. The model, pretrained weights, BERT assets, tokenizer/dictionary, recording corpus, and character voice rights each require separate provenance records; an ONNX conversion does not change their licenses.

Development proceeds under the conservative distribution boundary above: publish modifications and reproducible export tooling, keep upstream Python code outside the app, treat exported weights as covered, and avoid downstream restrictions on covered artifacts. A future alternative checkpoint or written commercial permission may relax model distribution, but the runtime architecture must not depend on obtaining it.

## Release gates

A voice is not production-ready until all gates pass:

1. **Rights:** complete provenance and license bundle; owner consent or signed performer agreement.
2. **Reproducibility:** pinned source commits and a repeatable checkpoint-to-pack export.
3. **Correctness:** Python and mobile frontend golden tensors match within declared tolerance.
4. **Offline:** airplane-mode cold launch and synthesis succeed with an installed pack.
5. **Performance:** meets latency, memory, storage, energy, and thermal targets on the oldest supported devices.
6. **Reliability:** alarms fall back to a bundled safe voice or prerecorded audio if a pack is missing or invalid.
7. **Distribution:** signature verification, atomic install, rollback, license display, and source link are tested.
8. **Subscription:** purchase, restore, expiry, offline grace behavior, and multi-device behavior are defined and tested.

## Implementation sequence

1. Train the first owner-voice Japanese model and export it and its BERT model to ONNX.
2. Capture exact tensor names, shapes, dtypes, opset, dynamic axes, model sizes, and checksums in a test fixture.
3. Implement the Japanese frontend and compare its tensors against upstream Python golden fixtures.
4. Add ONNX Runtime to iOS and synthesize from precomputed frontend tensors first.
5. Move the full frontend on-device and verify Airplane Mode operation.
6. Benchmark CPU, XNNPACK, and Core ML EP on physical devices.
7. Repeat the same contract on Android with CPU/XNNPACK/NNAPI.
8. Compare against the existing VOICEVOX PoC and make the adoption decision.

## Current next milestone

Record the first controlled owner-voice dataset, train the 15-minute checkpoint, export it to ONNX, and produce golden frontend tensors plus a reference WAV. This creates the first project-owned Voice Pack candidate and unblocks real iPhone inference work.

## Primary references

- [Style-Bert-VITS2 repository and license](https://github.com/litagin02/Style-Bert-VITS2)
- [Style-Bert-VITS2 ONNX converter](https://github.com/litagin02/Style-Bert-VITS2/blob/master/convert_onnx.py)
- [Style-Bert-VITS2 BERT ONNX converter](https://github.com/litagin02/Style-Bert-VITS2/blob/master/convert_bert_onnx.py)
- [ONNX Runtime mobile deployment](https://onnxruntime.ai/docs/tutorials/mobile/)
- [ONNX Runtime Core ML Execution Provider](https://onnxruntime.ai/docs/execution-providers/CoreML-ExecutionProvider.html)
