import { NavParam } from '../model/types';
import { NavPathStack } from '@kit.ArkUI';

class RouteState {
  static next: NavParam = new NavParam();
}

let sharedStack: NavPathStack | null = null;

export function navigationStack(): NavPathStack {
  if (sharedStack === null) {
    sharedStack = new NavPathStack();
  }
  return sharedStack;
}

export function openPage(stack: NavPathStack, name: string, plantId: string, careType: string, envId: string,
  recordId: string): void {
  const param = new NavParam();
  param.plantId = plantId;
  param.careType = careType;
  param.envId = envId;
  param.recordId = recordId;
  RouteState.next = param;
  stack.pushPathByName(name, param);
}

export function takeRoute(): NavParam {
  const current = RouteState.next;
  const copy = new NavParam();
  copy.plantId = current.plantId;
  copy.careType = current.careType;
  copy.envId = current.envId;
  copy.recordId = current.recordId;
  return copy;
}
