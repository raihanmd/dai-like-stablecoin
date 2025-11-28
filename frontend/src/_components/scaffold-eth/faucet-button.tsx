"use client";

import { useState } from "react";
import { useWatchBalance } from "@scaffold-ui/hooks";
import { createWalletClient, http, parseEther } from "viem";
import { anvil } from "viem/chains";
import { useConnection } from "wagmi";
import { useTransactor } from "~/hooks/scaffold-eth";
import { Banknote } from "lucide-react";

// Number of ETH faucet sends to an address
const NUM_OF_ETH = "1";
const FAUCET_ADDRESS = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";

const localWalletClient = createWalletClient({
  chain: anvil,
  transport: http(),
});

/**
 * FaucetButton button which lets you grab eth.
 */
export const FaucetButton = () => {
  const { address, chain: ConnectedChain } = useConnection();

  const { data: balance } = useWatchBalance({ address, chain: anvil });

  const [loading, setLoading] = useState(false);

  const faucetTxn = useTransactor(localWalletClient);

  const sendETH = async () => {
    if (!address) return;
    try {
      setLoading(true);
      await faucetTxn({
        account: FAUCET_ADDRESS,
        to: address,
        value: parseEther(NUM_OF_ETH),
      });
      setLoading(false);
    } catch (error) {
      console.error("⚡️ ~ file: FaucetButton.tsx:sendETH ~ error", error);
      setLoading(false);
    }
  };

  // Render only on local chain
  if (ConnectedChain?.id !== anvil.id) {
    return null;
  }

  const isBalanceZero = balance && balance.value === 0n;

  return (
    <div
      className={
        !isBalanceZero
          ? "ml-1"
          : "tooltip tooltip-bottom tooltip-primary tooltip-open ml-1 font-bold before:left-auto before:-translate-x-2/5 before:transform-none before:content-[attr(data-tip)]"
      }
      data-tip="Grab funds from faucet"
    >
      <button
        className="btn btn-secondary btn-sm rounded-full px-2"
        onClick={sendETH}
        disabled={loading}
      >
        {!loading ? (
          <Banknote className="h-4 w-4" />
        ) : (
          <span className="loading loading-spinner loading-xs"></span>
        )}
      </button>
    </div>
  );
};
