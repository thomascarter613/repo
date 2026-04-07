import { createStore } from "solid-js/store";

type AppStoreState = {
  sidebarOpen: boolean;
  commandPaletteOpen: boolean;
};

const [state, setState] = createStore<AppStoreState>({
  sidebarOpen: false,
  commandPaletteOpen: false
});

export const appStore = {
  state,
  openSidebar() {
    setState("sidebarOpen", true);
  },
  closeSidebar() {
    setState("sidebarOpen", false);
  },
  setCommandPaletteOpen(value: boolean) {
    setState("commandPaletteOpen", value);
  }
};
