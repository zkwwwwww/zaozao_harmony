import { fileIo } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { common } from '@kit.AbilityKit';
import { camera, cameraPicker } from '@kit.CameraKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';

let filesDir: string = '';

export function bindFilesDir(dir: string): void {
  filesDir = dir;
}

export function photosDir(): string {
  return filesDir + '/photos';
}

function ensureDir(path: string): void {
  try {
    if (!fileIo.accessSync(path)) {
      fileIo.mkdirSync(path);
    }
  } catch (err) {
    fileIo.mkdirSync(path);
  }
}

function extOf(uri: string): string {
  const clean = uri.split('?')[0];
  const dot = clean.lastIndexOf('.');
  if (dot < 0 || dot < clean.lastIndexOf('/')) return 'jpg';
  const ext = clean.substring(dot + 1).toLowerCase();
  if (ext === 'jpeg') return 'jpg';
  if (ext === 'png' || ext === 'jpg' || ext === 'webp' || ext === 'gif') return ext;
  return 'jpg';
}

function destPath(ext: string): string {
  ensureDir(photosDir());
  return photosDir() + '/' + Date.now() + '_' + Math.floor(Math.random() * 100000) + '.' + ext;
}

export function deleteIfOwned(path: string): void {
  if (path.length === 0 || filesDir.length === 0) return;
  if (path.indexOf(photosDir() + '/') !== 0) return;
  try {
    fileIo.unlinkSync(path);
  } catch (err) {
    return;
  }
}

export async function persistUri(uri: string): Promise<string> {
  const dest = destPath(extOf(uri));
  const src = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
  const dst = fileIo.openSync(dest, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
  try {
    fileIo.copyFileSync(src.fd, dst.fd);
  } finally {
    fileIo.closeSync(src);
    fileIo.closeSync(dst);
  }
  return dest;
}

export function readBase64(path: string): string {
  try {
    const file = fileIo.openSync(path, fileIo.OpenMode.READ_ONLY);
    const stat = fileIo.statSync(file.fd);
    if (stat.size <= 0) {
      fileIo.closeSync(file);
      return '';
    }
    const buf = new ArrayBuffer(stat.size);
    fileIo.readSync(file.fd, buf);
    fileIo.closeSync(file);
    const helper = new util.Base64Helper();
    return helper.encodeToStringSync(new Uint8Array(buf));
  } catch (err) {
    return '';
  }
}

export function writeBase64(data: string, ext: string): string {
  const helper = new util.Base64Helper();
  const bytes = helper.decodeSync(data);
  const copy = new ArrayBuffer(bytes.byteLength);
  const view = new Uint8Array(copy);
  view.set(bytes);
  const dest = destPath(ext.length > 0 ? ext : 'jpg');
  const file = fileIo.openSync(dest, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
  fileIo.writeSync(file.fd, copy);
  fileIo.closeSync(file);
  return dest;
}

function isCancel(err: Object): boolean {
  const text = err instanceof Error ? err.message.toLowerCase() : '';
  return text.indexOf('cancel') >= 0 || text.indexOf('取消') >= 0;
}

export async function pickPhotos(maxCount: number): Promise<string[]> {
  if (maxCount <= 0) return [];
  const picker = new photoAccessHelper.PhotoViewPicker();
  try {
    const result = await picker.select({
      MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
      maxSelectNumber: maxCount
    });
    const saved: string[] = [];
    const uris = result.photoUris;
    for (let i = 0; i < uris.length; i++) {
      saved.push(await persistUri(uris[i]));
    }
    return saved;
  } catch (err) {
    if (isCancel(err)) return [];
    throw new Error('选择照片失败，请重试');
  }
}

export async function takePhoto(context: common.UIAbilityContext): Promise<string> {
  const profile: cameraPicker.PickerProfile = {
    cameraPosition: camera.CameraPosition.CAMERA_POSITION_BACK
  };
  try {
    const result = await cameraPicker.pick(context, [cameraPicker.PickerMediaType.PHOTO], profile);
    if (result.resultCode !== 0 || result.resultUri.length === 0) return '';
    return await persistUri(result.resultUri);
  } catch (err) {
    if (isCancel(err)) return '';
    throw new Error('拍照失败，请重试');
  }
}
