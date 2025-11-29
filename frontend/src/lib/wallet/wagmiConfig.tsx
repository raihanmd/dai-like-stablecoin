import scaffoldConfig, {
  DEFAULT_ALCHEMY_API_KEY,
  type ScaffoldConfig,
} from "scaffold.config";
import { type Chain, createClient, fallback, http } from "viem";
import { anvil, mainnet } from "viem/chains";
import { createConfig } from "wagmi";
import { getAlchemyHttpUrl } from "../scaffold-eth";
import { wagmiConnectors } from "./wagmiConnectors";

const { targetNetworks } = scaffoldConfig;

// We always want to have mainnet enabled (ENS resolution, ETH price, etc). But only once.
export const enabledChains = targetNetworks.find(
  (network: Chain) => network.id === 1,
)
  ? targetNetworks
  : ([...targetNetworks, mainnet] as const);

export const wagmiConfig = createConfig({
  chains: enabledChains,
  connectors: wagmiConnectors(),
  ssr: true,
  client: ({ chain }) => {
    let rpcFallbacks = [http()];
    const rpcOverrideUrl = (
      scaffoldConfig.rpcOverrides as ScaffoldConfig["rpcOverrides"]
    )?.[chain.id];
    if (rpcOverrideUrl) {
      rpcFallbacks = [http(rpcOverrideUrl), http()];
    } else {
      const alchemyHttpUrl = getAlchemyHttpUrl(chain.id);
      if (alchemyHttpUrl) {
        const isUsingDefaultKey =
          scaffoldConfig.alchemyApiKey === DEFAULT_ALCHEMY_API_KEY;
        rpcFallbacks = isUsingDefaultKey
          ? [http(), http(alchemyHttpUrl)]
          : [http(alchemyHttpUrl), http()];
      }
    }
    return createClient({
      chain,
      transport: fallback(rpcFallbacks),
      ...(chain.id !== (anvil as Chain).id
        ? { pollingInterval: scaffoldConfig.pollingInterval }
        : {}),
    });
  },
});
