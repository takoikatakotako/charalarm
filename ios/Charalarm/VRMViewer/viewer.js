// キャラの VRM を表示する。Swift (VRMWebView) から ?model=<URL>&framing=<bust|full> で開く。
// 読み込みの結果は webkit.messageHandlers.vrm に { type: "loaded" | "error", message } で返す。
import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { VRMLoaderPlugin, VRMUtils } from '@pixiv/three-vrm';

const params = new URLSearchParams(location.search);
const modelURL = params.get('model');
const framing = params.get('framing') ?? 'bust';

function post(type, message = '') {
  window.webkit?.messageHandlers?.vrm?.postMessage({ type, message });
}

const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.outputColorSpace = THREE.SRGBColorSpace;
document.body.appendChild(renderer.domElement);

const scene = new THREE.Scene();
const camera = new THREE.PerspectiveCamera(30, window.innerWidth / window.innerHeight, 0.1, 20);

const light = new THREE.DirectionalLight(0xffffff, Math.PI);
light.position.set(0.5, 1.5, 2).normalize();
scene.add(light);
scene.add(new THREE.AmbientLight(0xffffff, 0.6));

let vrm = null;
const clock = new THREE.Clock();

// 頭の高さに合わせてカメラを置く。bust は胸から上、full は全身
function frameCamera() {
  const head = vrm.humanoid.getNormalizedBoneNode('head');
  const headY = head ? head.getWorldPosition(new THREE.Vector3()).y : 1.4;
  if (framing === 'full') {
    camera.position.set(0, headY * 0.55, 4.2);
    camera.lookAt(0, headY * 0.5, 0);
  } else {
    camera.position.set(0, headY - 0.05, 1.3);
    camera.lookAt(0, headY - 0.12, 0);
  }
}

// T ポーズのままにならないよう腕を下ろす (VRM 1.0 の正規化ボーン。キャラは +Z を向く)
function restPose() {
  const bone = (name) => vrm.humanoid.getNormalizedBoneNode(name);
  bone('leftUpperArm')?.rotation.set(0, 0, -1.2);
  bone('rightUpperArm')?.rotation.set(0, 0, 1.2);
  bone('leftLowerArm')?.rotation.set(0, -0.15, 0);
  bone('rightLowerArm')?.rotation.set(0, 0.15, 0);
}

// 呼吸と、表情があればまばたき
let nextBlink = 2;
function idle(elapsed) {
  const chest = vrm.humanoid.getNormalizedBoneNode('chest') ?? vrm.humanoid.getNormalizedBoneNode('spine');
  if (chest) chest.rotation.x = Math.sin(elapsed * 1.6) * 0.015;
  const neck = vrm.humanoid.getNormalizedBoneNode('neck');
  if (neck) neck.rotation.y = Math.sin(elapsed * 0.5) * 0.04;

  const expressions = vrm.expressionManager;
  if (expressions?.getExpression('blink')) {
    const t = elapsed - nextBlink;
    expressions.setValue('blink', t > 0 && t < 0.15 ? Math.sin((t / 0.15) * Math.PI) : 0);
    if (t >= 0.15) nextBlink = elapsed + 2 + Math.random() * 3;
  }
}

function animate() {
  requestAnimationFrame(animate);
  const delta = Math.min(clock.getDelta(), 0.1);
  if (vrm) {
    idle(clock.elapsedTime);
    vrm.update(delta);
  }
  renderer.render(scene, camera);
}

window.addEventListener('resize', () => {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
});

if (!modelURL) {
  post('error', 'model が指定されていません');
} else {
  const loader = new GLTFLoader();
  loader.register((parser) => new VRMLoaderPlugin(parser));
  loader.load(
    modelURL,
    (gltf) => {
      vrm = gltf.userData.vrm;
      if (!vrm) {
        post('error', 'VRM ではありません');
        return;
      }
      VRMUtils.removeUnnecessaryVertices(gltf.scene);
      VRMUtils.combineSkeletons(gltf.scene);
      VRMUtils.rotateVRM0(vrm);
      vrm.scene.traverse((object) => { object.frustumCulled = false; });
      scene.add(vrm.scene);
      restPose();
      vrm.update(0);
      frameCamera();
      post('loaded');
    },
    undefined,
    (error) => post('error', String(error?.message ?? error)),
  );
}

animate();
