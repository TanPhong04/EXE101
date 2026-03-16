import React from 'react';
import { Link } from 'react-router-dom';
import { 
  Layout, Shield, Users, Compass, Lock, 
  Settings, MessageSquare, Bell, CreditCard, 
  MapPin, Star, Calendar, DollarSign, Activity,
  Globe, LogIn, UserPlus, Heart, Flag
} from 'lucide-react';
import Navbar from '../../components/Navbar';

const categories = [
  {
    title: "Authentication & Onboarding",
    icon: Lock,
    color: "bg-blue-50 text-blue-500",
    pages: [
      { name: "Login", path: "/login", icon: LogIn },
      { name: "Signup", path: "/signup", icon: UserPlus },
      { name: "Forgot Password", path: "/forgot-password", icon: Lock },
      { name: "Reset Password", path: "/reset-password", icon: Shield },
      { name: "Buddy Registration", path: "/register/buddy", icon: Users },
    ]
  },
  {
    title: "Traveler Experience",
    icon: Compass,
    color: "bg-orange-50 text-orange-500",
    pages: [
      { name: "Explore Buddies", path: "/traveller/buddies", icon: Search },
      { name: "Matches", path: "/traveller/matches", icon: Heart },
      { name: "Match Confirmation", path: "/traveller/match", icon: Star },
      { name: "Plan Experience", path: "/traveller/plan/1", icon: MapPin },
      { name: "User Dashboard", path: "/traveller/booking", icon: Layout },
      { name: "Checkout", path: "/traveller/checkout", icon: CreditCard },
      { name: "Review Experience", path: "/traveller/review/1", icon: Star },
    ]
  },
  {
    title: "Buddy Management",
    icon: Users,
    color: "bg-green-50 text-green-500",
    pages: [
      { name: "Buddy Profile", path: "/profile/1", icon: Users },
    ]
  },
  {
    title: "Shared / Core",
    icon: Layout,
    color: "bg-purple-50 text-purple-500",
    pages: [
      { name: "Landing Page", path: "/", icon: Globe },
      { name: "Messaging", path: "/traveller/messages", icon: MessageSquare },
      { name: "Notifications", path: "/notifications", icon: Bell },
      { name: "Booking Details", path: "/traveller/booking/1", icon: Activity },
      { name: "Cancel Booking", path: "/traveller/booking/1/cancel", icon: Activity },
      { name: "Safety Dashboard", path: "/traveller/safety", icon: Shield },
      { name: "Edit Profile", path: "/traveller/profile/edit", icon: Settings },
      { name: "Report User", path: "/traveller/report/1", icon: Flag },
    ]
  },
  {
    title: "Admin Console",
    icon: Shield,
    color: "bg-red-50 text-red-500",
    pages: [
      { name: "Admin Dashboard", path: "/admin", icon: Layout },
      { name: "Verification Queue", path: "/admin/verification", icon: Shield },
      { name: "SOS Monitoring", path: "/admin/sos", icon: Activity },
    ]
  }
];

// Re-using Search icon since it's common
import { Search } from 'lucide-react';

const PageCatalog: React.FC = () => {
  return (
    <div className="min-h-screen bg-surface">
      <Navbar />
      
      <main className="max-w-7xl mx-auto px-4 sm:px-8 py-20 space-y-20">
        <header className="space-y-4 max-w-2xl">
          <h1 className="heading-hero tracking-tighter">Page Catalog</h1>
          <p className="text-xl font-bold text-secondary/40 tracking-tight leading-relaxed">
            Welcome to the central design hub. Here you can test every individual screen implemented in the Local Buddy ecosystem.
          </p>
        </header>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12">
          {categories.map((cat, i) => (
            <section key={i} className="bg-white rounded-[56px] shadow-premium p-10 border border-gray-50 space-y-8 group hover:shadow-premium-hover transition-all duration-500">
              <div className="flex items-center gap-4">
                <div className={`w-14 h-14 ${cat.color} rounded-[22px] flex items-center justify-center shadow-inner`}>
                  <cat.icon size={28} />
                </div>
                <h2 className="text-2xl font-black text-secondary tracking-tight">{cat.title}</h2>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                {cat.pages.map((page, j) => (
                  <Link 
                    key={j} 
                    to={page.path}
                    className="flex items-center gap-4 p-5 rounded-3xl bg-surface-dark/5 hover:bg-primary/5 hover:scale-[1.02] transition-all group/item border border-transparent hover:border-primary/10"
                  >
                    <div className="w-10 h-10 bg-white rounded-xl shadow-sm flex items-center justify-center text-secondary/20 group-hover/item:text-primary transition-colors">
                      <page.icon size={20} />
                    </div>
                    <span className="font-bold text-secondary text-sm tracking-tight">{page.name}</span>
                  </Link>
                ))}
              </div>
            </section>
          ))}
        </div>

        <footer className="pt-20 border-t border-gray-100 text-center">
          <p className="text-[10px] font-black text-secondary/10 uppercase tracking-[0.5em]">
            Local Buddy • Internal Development Hub • 2024
          </p>
        </footer>
      </main>
    </div>
  );
};

export default PageCatalog;
