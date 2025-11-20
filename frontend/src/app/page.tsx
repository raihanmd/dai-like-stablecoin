import ArchitectureSection from "~/_features/homepage/architecture-section";
import CTASection from "~/_features/homepage/cta-section";
import FeaturesSection from "~/_features/homepage/features-section";
import HeroSection from "~/_features/homepage/hero-section";
import { LightRays } from "~/components/ui/light-rays";

export default function HomePage() {
  return (
    <main className="min-h-screen w-full overflow-hidden">
      <LightRays />
      <HeroSection />
      <FeaturesSection />
      <ArchitectureSection />
      <CTASection />
    </main>
  );
}
