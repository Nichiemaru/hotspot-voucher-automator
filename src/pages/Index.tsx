
import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { toast } from "sonner";
import { Wifi, Clock, Users, Shield } from "lucide-react";

interface VoucherPackage {
  id: string;
  name: string;
  profile: string;
  price: number;
  duration: string;
  speed: string;
  description: string;
}

const Index = () => {
  const [selectedPackage, setSelectedPackage] = useState<VoucherPackage | null>(null);
  const [whatsappNumber, setWhatsappNumber] = useState("");
  const [isLoading, setIsLoading] = useState(false);

  // Sample voucher packages - in real app this would come from API
  const packages: VoucherPackage[] = [
    {
      id: "1",
      name: "Paket Hemat 1 Jam",
      profile: "1jam",
      price: 2000,
      duration: "1 Jam",
      speed: "2 Mbps",
      description: "Cocok untuk browsing ringan dan media sosial"
    },
    {
      id: "2", 
      name: "Paket Super Cepat 6 Jam",
      profile: "6jam",
      price: 5000,
      duration: "6 Jam",
      speed: "5 Mbps", 
      description: "Ideal untuk streaming dan download"
    },
    {
      id: "3",
      name: "Paket Premium 24 Jam", 
      profile: "1hari",
      price: 10000,
      duration: "24 Jam",
      speed: "10 Mbps",
      description: "Unlimited browsing untuk seharian penuh"
    },
    {
      id: "4",
      name: "Paket Mingguan",
      profile: "1minggu", 
      price: 50000,
      duration: "7 Hari",
      speed: "10 Mbps",
      description: "Paket hemat untuk kebutuhan seminggu"
    }
  ];

  const handleBuyPackage = (pkg: VoucherPackage) => {
    setSelectedPackage(pkg);
  };

  const handlePurchase = async () => {
    if (!whatsappNumber) {
      toast.error("Nomor WhatsApp harus diisi!");
      return;
    }

    if (!whatsappNumber.match(/^(\+62|62|0)[0-9]{9,13}$/)) {
      toast.error("Format nomor WhatsApp tidak valid!");
      return;
    }

    setIsLoading(true);
    
    // Simulate payment processing
    setTimeout(() => {
      toast.success(`Pembelian berhasil! Voucher ${selectedPackage?.name} akan dikirim ke WhatsApp ${whatsappNumber}`);
      setSelectedPackage(null);
      setWhatsappNumber("");
      setIsLoading(false);
    }, 2000);
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('id-ID', {
      style: 'currency',
      currency: 'IDR',
      minimumFractionDigits: 0
    }).format(amount);
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-green-50">
      {/* Header */}
      <header className="bg-white/80 backdrop-blur-sm shadow-sm sticky top-0 z-40">
        <div className="container mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-2">
              <div className="bg-gradient-to-r from-blue-600 to-green-600 p-2 rounded-lg">
                <Wifi className="h-6 w-6 text-white" />
              </div>
              <div>
                <h1 className="text-xl font-bold text-gray-900">HotSpot Voucher</h1>
                <p className="text-sm text-gray-600">Internet Cepat & Terpercaya</p>
              </div>
            </div>
            <Button 
              variant="outline" 
              onClick={() => window.open('/admin', '_blank')}
              className="text-blue-600 border-blue-200 hover:bg-blue-50"
            >
              Admin Panel
            </Button>
          </div>
        </div>
      </header>

      {/* Hero Section */}
      <section className="py-16 px-4">
        <div className="container mx-auto text-center">
          <h2 className="text-4xl md:text-5xl font-bold text-gray-900 mb-4">
            Akses Internet <span className="text-transparent bg-clip-text bg-gradient-to-r from-blue-600 to-green-600">Super Cepat</span>
          </h2>
          <p className="text-xl text-gray-600 mb-8 max-w-2xl mx-auto">
            Dapatkan voucher internet hotspot dengan harga terjangkau dan kecepatan tinggi. 
            Proses otomatis dan voucher langsung dikirim ke WhatsApp Anda!
          </p>
          
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8 max-w-4xl mx-auto mb-12">
            <div className="flex flex-col items-center">
              <div className="bg-blue-100 p-3 rounded-full mb-3">
                <Clock className="h-6 w-6 text-blue-600" />
              </div>
              <h3 className="font-semibold text-gray-900 mb-1">Proses Cepat</h3>
              <p className="text-gray-600 text-sm">Voucher langsung aktif setelah pembayaran</p>
            </div>
            <div className="flex flex-col items-center">
              <div className="bg-green-100 p-3 rounded-full mb-3">
                <Shield className="h-6 w-6 text-green-600" />
              </div>
              <h3 className="font-semibold text-gray-900 mb-1">Aman & Terpercaya</h3>
              <p className="text-gray-600 text-sm">Sistem pembayaran yang aman dan terjamin</p>
            </div>
            <div className="flex flex-col items-center">
              <div className="bg-purple-100 p-3 rounded-full mb-3">
                <Users className="h-6 w-6 text-purple-600" />
              </div>
              <h3 className="font-semibold text-gray-900 mb-1">24/7 Support</h3>
              <p className="text-gray-600 text-sm">Dukungan pelanggan siap membantu Anda</p>
            </div>
          </div>
        </div>
      </section>

      {/* Packages Section */}
      <section className="py-16 px-4 bg-white/50">
        <div className="container mx-auto">
          <h2 className="text-3xl font-bold text-center text-gray-900 mb-4">
            Pilih Paket Internet Anda
          </h2>
          <p className="text-gray-600 text-center mb-12 max-w-2xl mx-auto">
            Berbagai pilihan paket internet dengan harga terjangkau dan kecepatan tinggi
          </p>
          
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 max-w-7xl mx-auto">
            {packages.map((pkg) => (
              <Card key={pkg.id} className="relative group hover:shadow-xl transition-all duration-300 border-0 shadow-lg bg-white/80 backdrop-blur-sm">
                <CardHeader className="text-center pb-4">
                  <div className="bg-gradient-to-r from-blue-500 to-green-500 text-white px-3 py-1 rounded-full text-sm font-medium mb-3 inline-block">
                    {pkg.duration}
                  </div>
                  <CardTitle className="text-xl font-bold text-gray-900">{pkg.name}</CardTitle>
                  <CardDescription className="text-gray-600">{pkg.description}</CardDescription>
                </CardHeader>
                
                <CardContent className="text-center pb-6">
                  <div className="text-3xl font-bold text-gray-900 mb-4">
                    {formatCurrency(pkg.price)}
                  </div>
                  
                  <div className="space-y-2 text-sm text-gray-600">
                    <div className="flex items-center justify-center space-x-2">
                      <Clock className="h-4 w-4" />
                      <span>Durasi: {pkg.duration}</span>
                    </div>
                    <div className="flex items-center justify-center space-x-2">
                      <Wifi className="h-4 w-4" />
                      <span>Kecepatan: {pkg.speed}</span>
                    </div>
                  </div>
                </CardContent>
                
                <CardFooter>
                  <Button 
                    onClick={() => handleBuyPackage(pkg)}
                    className="w-full bg-gradient-to-r from-blue-600 to-green-600 hover:from-blue-700 hover:to-green-700 text-white font-semibold py-2 rounded-lg transition-all duration-300 transform group-hover:scale-105"
                  >
                    Beli Sekarang
                  </Button>
                </CardFooter>
              </Card>
            ))}
          </div>
        </div>
      </section>

      {/* Purchase Dialog */}
      <Dialog open={selectedPackage !== null} onOpenChange={() => setSelectedPackage(null)}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle>Pembelian Voucher</DialogTitle>
            <DialogDescription>
              Anda akan membeli {selectedPackage?.name} seharga {selectedPackage ? formatCurrency(selectedPackage.price) : ''}
            </DialogDescription>
          </DialogHeader>
          
          <div className="space-y-4">
            <div>
              <Label htmlFor="whatsapp">Nomor WhatsApp</Label>
              <Input
                id="whatsapp"
                placeholder="Contoh: 081234567890"
                value={whatsappNumber}
                onChange={(e) => setWhatsappNumber(e.target.value)}
                className="mt-1"
              />
              <p className="text-xs text-gray-500 mt-1">
                Voucher akan dikirim ke nomor WhatsApp ini
              </p>
            </div>
          </div>
          
          <DialogFooter className="flex gap-2">
            <Button variant="outline" onClick={() => setSelectedPackage(null)}>
              Batal
            </Button>
            <Button 
              onClick={handlePurchase}
              disabled={isLoading}
              className="bg-gradient-to-r from-blue-600 to-green-600 hover:from-blue-700 hover:to-green-700"
            >
              {isLoading ? "Memproses..." : "Bayar Sekarang"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Footer */}
      <footer className="bg-gray-900 text-white py-12">
        <div className="container mx-auto px-4">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            <div>
              <div className="flex items-center space-x-2 mb-4">
                <div className="bg-gradient-to-r from-blue-600 to-green-600 p-2 rounded-lg">
                  <Wifi className="h-5 w-5 text-white" />
                </div>
                <span className="text-xl font-bold">HotSpot Voucher</span>
              </div>
              <p className="text-gray-400">
                Penyedia voucher internet hotspot terpercaya dengan layanan 24/7
              </p>
            </div>
            
            <div>
              <h3 className="text-lg font-semibold mb-4">Kontak</h3>
              <div className="space-y-2 text-gray-400">
                <p>WhatsApp: +62 812-3456-7890</p>
                <p>Email: support@hotspotvoucher.com</p>
                <p>Jam Operasional: 24/7</p>
              </div>
            </div>
            
            <div>
              <h3 className="text-lg font-semibold mb-4">Informasi</h3>
              <div className="space-y-2">
                <a href="#" className="text-gray-400 hover:text-white transition-colors">Cara Penggunaan</a>
                <a href="#" className="text-gray-400 hover:text-white transition-colors">Syarat & Ketentuan</a>
                <a href="#" className="text-gray-400 hover:text-white transition-colors">Kebijakan Privasi</a>
              </div>
            </div>
          </div>
          
          <div className="border-t border-gray-800 mt-8 pt-6 text-center text-gray-400">
            <p>&copy; 2024 HotSpot Voucher. All rights reserved.</p>
          </div>
        </div>
      </footer>
    </div>
  );
};

export default Index;
