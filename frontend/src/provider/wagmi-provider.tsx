"use client";

import "@rainbow-me/rainbowkit/styles.css";

import { midnightTheme, RainbowKitProvider } from "@rainbow-me/rainbowkit";
import { type PropsWithChildren } from "react";
import { WagmiProvider as _WagmiProvider } from "wagmi";

import { config } from "~/lib/wallet/rainbow-config";

export default function WagmiProvider({ children }: PropsWithChildren) {
  return (
    <_WagmiProvider config={config}>
      <RainbowKitProvider
        showRecentTransactions
        theme={midnightTheme({
          fontStack: "rounded",
          accentColor: "#7b3fe4",
          accentColorForeground: "white",
          borderRadius: "medium",
          overlayBlur: "small",
        })}
      >
        {children}
      </RainbowKitProvider>
    </_WagmiProvider>
  );
}
