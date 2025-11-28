"use client";
import {
  useDeployedContractInfo,
  useScaffoldReadContract,
} from "~/hooks/scaffold-eth";

export default function TotalSupply() {
  const { data: DSCContract } = useDeployedContractInfo({
    contractName: "DecentralizedStableCoin",
  });

  const { data: balaceDSC } = useScaffoldReadContract({
    contractName: "DecentralizedStableCoin",
    functionName: "balanceOf",
    args: [DSCContract?.address],
  });

  return (
    <div className="h-screen w-full">
      <p className="text-white">{balaceDSC}</p>
    </div>
  );
}
