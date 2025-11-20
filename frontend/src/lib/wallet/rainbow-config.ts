"use client";

import { getDefaultConfig } from "@rainbow-me/rainbowkit";
import { mainnet, sepolia, base, baseSepolia, anvil } from "wagmi/chains";
import { env } from "~/env";

export const config = getDefaultConfig({
  appName: "Decentralized Stable Coin",
  projectId: env.NEXT_PUBLIC_REOWN_APP_ID,
  chains: [mainnet, sepolia, base, baseSepolia, anvil],
  ssr: true,
});
