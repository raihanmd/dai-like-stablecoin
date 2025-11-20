import { CheckCircle2 } from "lucide-react";

const features = [
  {
    title: "Over-Collateralized",
    description:
      "Minimum 200% collateral ratio ensures protocol stability and user protection.",
  },
  {
    title: "Trustless & Permissionless",
    description:
      "No governance tokens or centralized control. Fully algorithmic and transparent.",
  },
  {
    title: "Real-Time Pricing",
    description:
      "Integrated with Pyth Network for sub-second price updates and accuracy.",
  },
  {
    title: "Dual Collateral Support",
    description:
      "Accept WETH and WBTC as collateral with dynamic risk management.",
  },
  {
    title: "Liquidation Mechanism",
    description:
      "10% bonus incentives for liquidators to maintain protocol health.",
  },
  {
    title: "Gas Optimized",
    description:
      "Efficient contract design with minimal storage patterns for cost savings.",
  },
];

export default function FeaturesSection() {
  return (
    <section className="relative px-4 py-20 sm:px-6 lg:px-8">
      <div className="mx-auto max-w-6xl">
        <div className="mb-16 space-y-4 text-center">
          <h2 className="text-4xl font-bold tracking-tight sm:text-5xl">
            Core Features
          </h2>
          <p className="text-muted-foreground mx-auto max-w-2xl text-lg">
            Built with security, efficiency, and sustainability in mind.
          </p>
        </div>

        <div className="grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-3">
          {features.map((feature, idx) => (
            <div
              key={idx}
              className="border-border/50 bg-muted/30 hover:bg-muted/50 space-y-3 rounded-xl border p-6 transition-colors"
            >
              <div className="flex items-start gap-3">
                <CheckCircle2 className="text-muted-foreground mt-1 h-5 w-5 shrink-0" />
                <div className="flex-1 space-y-2">
                  <h3 className="text-foreground font-semibold">
                    {feature.title}
                  </h3>
                  <p className="text-muted-foreground text-sm">
                    {feature.description}
                  </p>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
