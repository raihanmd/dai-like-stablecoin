import { useEffect, useMemo } from "react";
import scaffoldConfig from "scaffold.config";
import { useConnection } from "wagmi";
import {
  NETWORKS_EXTRA_DATA,
  type ChainWithAttributes,
} from "~/lib/scaffold-eth";
import { useGlobalState } from "~/store/store";

/**
 * Retrieves the connected wallet's network from scaffold.config or defaults to the 0th network in the list if the wallet is not connected.
 */
export function useTargetNetwork(): { targetNetwork: ChainWithAttributes } {
  const { chain } = useConnection();
  const targetNetwork = useGlobalState(({ targetNetwork }) => targetNetwork);
  const setTargetNetwork = useGlobalState(
    ({ setTargetNetwork }) => setTargetNetwork,
  );

  useEffect(() => {
    const newSelectedNetwork = scaffoldConfig.targetNetworks.find(
      (targetNetwork) => targetNetwork.id === chain?.id,
    );
    if (newSelectedNetwork && newSelectedNetwork.id !== targetNetwork.id) {
      setTargetNetwork({
        ...newSelectedNetwork,
        ...NETWORKS_EXTRA_DATA[newSelectedNetwork.id],
      });
    }
  }, [chain?.id, setTargetNetwork, targetNetwork.id]);

  return useMemo(() => ({ targetNetwork }), [targetNetwork]);
}
