"use client";

import { getDefaultConfig } from "@rainbow-me/rainbowkit";
import type { _chains } from "node_modules/@rainbow-me/rainbowkit/dist/config/getDefaultConfig";
import { sepolia, anvil, baseSepolia } from "wagmi/chains";
import { env } from "~/env";

const chains: _chains = (() => {
  switch (env.NEXT_PUBLIC_ENV) {
    case "production":
      return [sepolia, baseSepolia];
    default:
      return [anvil];
  }
})();

export const config = getDefaultConfig({
  appName: "Decentralized Stable Coin",
  projectId: env.NEXT_PUBLIC_REOWN_APP_ID,
  chains,
  ssr: true,
});
