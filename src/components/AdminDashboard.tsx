import { useState } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Badge } from "@/components/ui/badge";
import { toast } from "sonner";
import { 
  Settings, 
  Wifi, 
  CreditCard, 
  Package, 
  MessageSquare, 
  Globe,
  TestTube,
  Save,
  Copy,
  Trash2,
  Plus,
  Lock,
  User
} from "lucide-react";

interface MikrotikConfig {
  ipAddress: string;
  username: string;
  password: string;
}

interface PaymentConfig {
  merchantCode: string;
  apiKey: string;
  privateKey: string;
}

interface WhatsAppConfig {
  endpoint: string;
  apiKey: string;
}

interface VoucherProfile {
  name: string;
  displayName: string;
  price: number;
  enabled: boolean;
}

interface AdminCredentials {
  currentPassword: string;
  newUsername: string;
  newPassword: string;
  confirmPassword: string;
}

const AdminDashboard = () => {
  const [mikrotikConfig, setMikrotikConfig] = useState<MikrotikConfig>({
    ipAddress: "",
    username: "",
    password: ""
  });

  const [paymentConfig, setPaymentConfig] = useState<PaymentConfig>({
    merchantCode: "",
    apiKey: "",
    privateKey: ""
  });

  const [whatsappConfig, setWhatsAppConfig] = useState<WhatsAppConfig>({
    endpoint: "",
    apiKey: ""
  });

  const [adminCredentials, setAdminCredentials] = useState<AdminCredentials>({
    currentPassword: "",
    newUsername: "admin",
    newPassword: "",
    confirmPassword: ""
  });

  const [profiles, setProfiles] = useState<VoucherProfile[]>([
    { name: "1jam", displayName: "Paket Hemat 1 Jam", price: 2000, enabled: true },
    { name: "6jam", displayName: "Paket Super Cepat 6 Jam", price: 5000, enabled: true },
    { name: "1hari", displayName: "Paket Premium 24 Jam", price: 10000, enabled: true },
    { name: "1minggu", displayName: "Paket Mingguan", price: 50000, enabled: true }
  ]);

  const [isTestingConnection, setIsTestingConnection] = useState(false);

  const handleTestMikrotikConnection = async () => {
    setIsTestingConnection(true);
    
    // Simulate connection test
    setTimeout(() => {
      if (mikrotikConfig.ipAddress && mikrotikConfig.username && mikrotikConfig.password) {
        toast.success("Koneksi MikroTik berhasil!");
      } else {
        toast.error("Gagal terhubung ke MikroTik. Periksa konfigurasi Anda.");
      }
      setIsTestingConnection(false);
    }, 2000);
  };

  const handleSaveMikrotikConfig = () => {
    console.log("Saving MikroTik config:", mikrotikConfig);
    toast.success("Konfigurasi MikroTik berhasil disimpan!");
  };

  const handleSavePaymentConfig = () => {
    console.log("Saving payment config:", paymentConfig);
    toast.success("Konfigurasi payment gateway berhasil disimpan!");
  };

  const handleSaveWhatsAppConfig = () => {
    console.log("Saving WhatsApp config:", whatsappConfig);
    toast.success("Konfigurasi WhatsApp berhasil disimpan!");
  };

  const handleUpdateProfile = (index: number, updates: Partial<VoucherProfile>) => {
    const updatedProfiles = [...profiles];
    updatedProfiles[index] = { ...updatedProfiles[index], ...updates };
    setProfiles(updatedProfiles);
  };

  const handleSaveProfiles = () => {
    console.log("Saving profiles:", profiles);
    toast.success("Konfigurasi paket berhasil disimpan!");
  };

  const handleUpdateAdminCredentials = () => {
    if (!adminCredentials.currentPassword) {
      toast.error("Password saat ini harus diisi!");
      return;
    }

    if (adminCredentials.newPassword && adminCredentials.newPassword !== adminCredentials.confirmPassword) {
      toast.error("Password baru dan konfirmasi password tidak cocok!");
      return;
    }

    // Simulate password verification
    if (adminCredentials.currentPassword !== "admin123") {
      toast.error("Password saat ini salah!");
      return;
    }

    console.log("Updating admin credentials:", {
      username: adminCredentials.newUsername,
      passwordChanged: !!adminCredentials.newPassword
    });

    // Update localStorage with new credentials if needed
    if (adminCredentials.newPassword) {
      // In a real app, this would be handled by the backend
      toast.success("Username dan password berhasil diperbarui!");
    } else {
      toast.success("Username berhasil diperbarui!");
    }

    // Reset form
    setAdminCredentials(prev => ({
      ...prev,
      currentPassword: "",
      newPassword: "",
      confirmPassword: ""
    }));
  };

  const callbackUrl = `${window.location.origin}/callback.php`;
  const landingPageUrl = window.location.origin;

  const copyToClipboard = (text: string) => {
    navigator.clipboard.writeText(text);
    toast.success("URL berhasil disalin!");
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 to-blue-50 p-6">
      <div className="max-w-6xl mx-auto">
        {/* Header */}
        <div className="mb-8">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-3xl font-bold text-gray-900 mb-2">Admin Dashboard</h1>
              <p className="text-gray-600">Kelola konfigurasi sistem voucher hotspot</p>
            </div>
            <Button 
              variant="outline" 
              onClick={() => window.open('/', '_blank')}
              className="flex items-center space-x-2"
            >
              <Globe className="h-4 w-4" />
              <span>Lihat Landing Page</span>
            </Button>
          </div>
        </div>

        {/* Quick Info Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
          <Card className="bg-gradient-to-r from-blue-500 to-blue-600 text-white">
            <CardHeader>
              <CardTitle className="flex items-center space-x-2">
                <Globe className="h-5 w-5" />
                <span>Landing Page URL</span>
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="flex items-center justify-between">
                <code className="text-sm bg-white/20 px-2 py-1 rounded truncate flex-1 mr-2">
                  {landingPageUrl}
                </code>
                <Button 
                  size="sm" 
                  variant="secondary"
                  onClick={() => copyToClipboard(landingPageUrl)}
                >
                  <Copy className="h-4 w-4" />
                </Button>
              </div>
            </CardContent>
          </Card>

          <Card className="bg-gradient-to-r from-green-500 to-green-600 text-white">
            <CardHeader>
              <CardTitle className="flex items-center space-x-2">
                <CreditCard className="h-5 w-5" />
                <span>Callback URL</span>
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="flex items-center justify-between">
                <code className="text-sm bg-white/20 px-2 py-1 rounded truncate flex-1 mr-2">
                  {callbackUrl}
                </code>
                <Button 
                  size="sm" 
                  variant="secondary"
                  onClick={() => copyToClipboard(callbackUrl)}
                >
                  <Copy className="h-4 w-4" />
                </Button>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Main Configuration Tabs */}
        <Tabs defaultValue="mikrotik" className="space-y-6">
          <TabsList className="grid w-full grid-cols-5 lg:w-auto lg:grid-cols-5">
            <TabsTrigger value="mikrotik" className="flex items-center space-x-2">
              <Wifi className="h-4 w-4" />
              <span className="hidden sm:inline">MikroTik</span>
            </TabsTrigger>
            <TabsTrigger value="payment" className="flex items-center space-x-2">
              <CreditCard className="h-4 w-4" />
              <span className="hidden sm:inline">Payment</span>
            </TabsTrigger>
            <TabsTrigger value="packages" className="flex items-center space-x-2">
              <Package className="h-4 w-4" />
              <span className="hidden sm:inline">Paket</span>
            </TabsTrigger>
            <TabsTrigger value="whatsapp" className="flex items-center space-x-2">
              <MessageSquare className="h-4 w-4" />
              <span className="hidden sm:inline">WhatsApp</span>
            </TabsTrigger>
            <TabsTrigger value="admin" className="flex items-center space-x-2">
              <Settings className="h-4 w-4" />
              <span className="hidden sm:inline">Admin</span>
            </TabsTrigger>
          </TabsList>

          {/* MikroTik Configuration */}
          <TabsContent value="mikrotik">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center space-x-2">
                  <Wifi className="h-5 w-5" />
                  <span>Konfigurasi MikroTik</span>
                </CardTitle>
                <CardDescription>
                  Atur koneksi ke router MikroTik untuk manajemen hotspot user
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <Label htmlFor="mikrotik-ip">IP Address MikroTik</Label>
                    <Input
                      id="mikrotik-ip"
                      placeholder="192.168.1.1"
                      value={mikrotikConfig.ipAddress}
                      onChange={(e) => setMikrotikConfig(prev => ({ ...prev, ipAddress: e.target.value }))}
                    />
                  </div>
                  <div>
                    <Label htmlFor="mikrotik-username">Username API</Label>
                    <Input
                      id="mikrotik-username"
                      placeholder="admin"
                      value={mikrotikConfig.username}
                      onChange={(e) => setMikrotikConfig(prev => ({ ...prev, username: e.target.value }))}
                    />
                  </div>
                </div>
                <div>
                  <Label htmlFor="mikrotik-password">Password API</Label>
                  <Input
                    id="mikrotik-password"
                    type="password"
                    placeholder="Masukkan password"
                    value={mikrotikConfig.password}
                    onChange={(e) => setMikrotikConfig(prev => ({ ...prev, password: e.target.value }))}
                  />
                </div>
                <div className="flex space-x-3">
                  <Button 
                    onClick={handleTestMikrotikConnection}
                    disabled={isTestingConnection}
                    variant="outline"
                    className="flex items-center space-x-2"
                  >
                    <TestTube className="h-4 w-4" />
                    <span>{isTestingConnection ? "Testing..." : "Tes Koneksi"}</span>
                  </Button>
                  <Button onClick={handleSaveMikrotikConfig} className="flex items-center space-x-2">
                    <Save className="h-4 w-4" />
                    <span>Simpan Konfigurasi</span>
                  </Button>
                </div>
              </CardContent>
            </Card>
          </TabsContent>

          {/* Payment Configuration */}
          <TabsContent value="payment">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center space-x-2">
                  <CreditCard className="h-5 w-5" />
                  <span>Konfigurasi Payment Gateway (TriPay)</span>
                </CardTitle>
                <CardDescription>
                  Atur kredensial TriPay untuk proses pembayaran otomatis
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div>
                  <Label htmlFor="merchant-code">Merchant Code</Label>
                  <Input
                    id="merchant-code"
                    placeholder="Masukkan merchant code"
                    value={paymentConfig.merchantCode}
                    onChange={(e) => setPaymentConfig(prev => ({ ...prev, merchantCode: e.target.value }))}
                  />
                </div>
                <div>
                  <Label htmlFor="api-key">API Key</Label>
                  <Input
                    id="api-key"
                    placeholder="Masukkan API key"
                    value={paymentConfig.apiKey}
                    onChange={(e) => setPaymentConfig(prev => ({ ...prev, apiKey: e.target.value }))}
                  />
                </div>
                <div>
                  <Label htmlFor="private-key">Private Key</Label>
                  <Input
                    id="private-key"
                    type="password"
                    placeholder="Masukkan private key"
                    value={paymentConfig.privateKey}
                    onChange={(e) => setPaymentConfig(prev => ({ ...prev, privateKey: e.target.value }))}
                  />
                </div>
                
                <div className="bg-blue-50 p-4 rounded-lg">
                  <h4 className="font-semibold text-blue-900 mb-2">URL Callback untuk TriPay:</h4>
                  <div className="flex items-center space-x-2">
                    <code className="bg-white px-3 py-2 rounded border text-sm flex-1">
                      {callbackUrl}
                    </code>
                    <Button 
                      size="sm" 
                      variant="outline"
                      onClick={() => copyToClipboard(callbackUrl)}
                    >
                      <Copy className="h-4 w-4" />
                    </Button>
                  </div>
                  <p className="text-sm text-blue-700 mt-2">
                    Salin URL ini dan masukkan ke dashboard TriPay Anda sebagai callback URL
                  </p>
                </div>

                <Button onClick={handleSavePaymentConfig} className="flex items-center space-x-2">
                  <Save className="h-4 w-4" />
                  <span>Simpan Konfigurasi</span>
                </Button>
              </CardContent>
            </Card>
          </TabsContent>

          {/* Package Management */}
          <TabsContent value="packages">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center space-x-2">
                  <Package className="h-5 w-5" />
                  <span>Manajemen Paket Voucher</span>
                </CardTitle>
                <CardDescription>
                  Atur harga dan nama tampilan untuk setiap profil user MikroTik
                </CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {profiles.map((profile, index) => (
                    <div key={profile.name} className="bg-gray-50 p-4 rounded-lg">
                      <div className="grid grid-cols-1 md:grid-cols-4 gap-4 items-end">
                        <div>
                          <Label>Profil User</Label>
                          <div className="flex items-center space-x-2 mt-1">
                            <Badge variant="secondary">{profile.name}</Badge>
                            <Badge variant={profile.enabled ? "default" : "secondary"}>
                              {profile.enabled ? "Aktif" : "Nonaktif"}
                            </Badge>
                          </div>
                        </div>
                        <div>
                          <Label htmlFor={`name-${index}`}>Nama Paket</Label>
                          <Input
                            id={`name-${index}`}
                            value={profile.displayName}
                            onChange={(e) => handleUpdateProfile(index, { displayName: e.target.value })}
                          />
                        </div>
                        <div>
                          <Label htmlFor={`price-${index}`}>Harga (IDR)</Label>
                          <Input
                            id={`price-${index}`}
                            type="number"
                            value={profile.price}
                            onChange={(e) => handleUpdateProfile(index, { price: parseInt(e.target.value) || 0 })}
                          />
                        </div>
                        <div className="flex space-x-2">
                          <Button
                            size="sm"
                            variant={profile.enabled ? "destructive" : "default"}
                            onClick={() => handleUpdateProfile(index, { enabled: !profile.enabled })}
                          >
                            {profile.enabled ? "Nonaktifkan" : "Aktifkan"}
                          </Button>
                        </div>
                      </div>
                    </div>
                  ))}

                  <div className="flex justify-between items-center pt-4 border-t">
                    <p className="text-sm text-gray-600">
                      * Profil user akan otomatis diambil dari MikroTik saat koneksi berhasil
                    </p>
                    <Button onClick={handleSaveProfiles} className="flex items-center space-x-2">
                      <Save className="h-4 w-4" />
                      <span>Simpan Semua Paket</span>
                    </Button>
                  </div>
                </div>
              </CardContent>
            </Card>
          </TabsContent>

          {/* WhatsApp Configuration */}
          <TabsContent value="whatsapp">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center space-x-2">
                  <MessageSquare className="h-5 w-5" />
                  <span>Konfigurasi WhatsApp Gateway</span>
                </CardTitle>
                <CardDescription>
                  Atur layanan WhatsApp gateway untuk pengiriman voucher otomatis
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div>
                  <Label htmlFor="wa-endpoint">Endpoint URL</Label>
                  <Input
                    id="wa-endpoint"
                    placeholder="https://api.whatsapp-gateway.com/send"
                    value={whatsappConfig.endpoint}
                    onChange={(e) => setWhatsAppConfig(prev => ({ ...prev, endpoint: e.target.value }))}
                  />
                </div>
                <div>
                  <Label htmlFor="wa-api-key">API Key</Label>
                  <Input
                    id="wa-api-key"
                    placeholder="Masukkan API key WhatsApp gateway"
                    value={whatsappConfig.apiKey}
                    onChange={(e) => setWhatsAppConfig(prev => ({ ...prev, apiKey: e.target.value }))}
                  />
                </div>

                <div className="bg-green-50 p-4 rounded-lg">
                  <h4 className="font-semibold text-green-900 mb-2">Template Pesan:</h4>
                  <div className="bg-white p-3 rounded border text-sm">
                    <p><strong>Voucher Internet Berhasil Dibeli!</strong></p>
                    <p>Paket: [NAMA_PAKET]</p>
                    <p>Username: [USERNAME]</p>
                    <p>Password: [PASSWORD]</p>
                    <p>Cara login: Buka browser → ketik 192.168.1.1 → masukkan username & password</p>
                    <p><em>Terima kasih telah menggunakan layanan kami!</em></p>
                  </div>
                </div>

                <Button onClick={handleSaveWhatsAppConfig} className="flex items-center space-x-2">
                  <Save className="h-4 w-4" />
                  <span>Simpan Konfigurasi</span>
                </Button>
              </CardContent>
            </Card>
          </TabsContent>

          {/* Admin Settings */}
          <TabsContent value="admin">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center space-x-2">
                  <Settings className="h-5 w-5" />
                  <span>Pengaturan Akun Admin</span>
                </CardTitle>
                <CardDescription>
                  Ubah username dan password untuk keamanan panel admin
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="bg-yellow-50 p-4 rounded-lg mb-4">
                  <div className="flex items-center space-x-2">
                    <Lock className="h-5 w-5 text-yellow-600" />
                    <h4 className="font-semibold text-yellow-800">Keamanan Penting</h4>
                  </div>
                  <p className="text-sm text-yellow-700 mt-2">
                    Pastikan untuk menggunakan password yang kuat dan unik untuk melindungi panel admin Anda.
                  </p>
                </div>

                <div>
                  <Label htmlFor="current-password">Password Saat Ini *</Label>
                  <Input
                    id="current-password"
                    type="password"
                    placeholder="Masukkan password saat ini"
                    value={adminCredentials.currentPassword}
                    onChange={(e) => setAdminCredentials(prev => ({ ...prev, currentPassword: e.target.value }))}
                    required
                  />
                </div>

                <div>
                  <Label htmlFor="new-username">Username Baru</Label>
                  <Input
                    id="new-username"
                    type="text"
                    placeholder="Masukkan username baru"
                    value={adminCredentials.newUsername}
                    onChange={(e) => setAdminCredentials(prev => ({ ...prev, newUsername: e.target.value }))}
                  />
                  <p className="text-sm text-gray-600 mt-1">Username saat ini: <strong>admin</strong></p>
                </div>

                <div>
                  <Label htmlFor="new-password">Password Baru (Opsional)</Label>
                  <Input
                    id="new-password"
                    type="password"
                    placeholder="Masukkan password baru"
                    value={adminCredentials.newPassword}
                    onChange={(e) => setAdminCredentials(prev => ({ ...prev, newPassword: e.target.value }))}
                  />
                  <p className="text-sm text-gray-600 mt-1">Kosongkan jika tidak ingin mengubah password</p>
                </div>

                {adminCredentials.newPassword && (
                  <div>
                    <Label htmlFor="confirm-password">Konfirmasi Password Baru</Label>
                    <Input
                      id="confirm-password"
                      type="password"
                      placeholder="Konfirmasi password baru"
                      value={adminCredentials.confirmPassword}
                      onChange={(e) => setAdminCredentials(prev => ({ ...prev, confirmPassword: e.target.value }))}
                    />
                  </div>
                )}

                <div className="bg-blue-50 p-4 rounded-lg">
                  <h4 className="font-semibold text-blue-900 mb-2">Info Keamanan:</h4>
                  <ul className="text-sm text-blue-700 space-y-1">
                    <li>• Gunakan kombinasi huruf besar, huruf kecil, angka, dan simbol</li>
                    <li>• Minimal 8 karakter untuk password</li>
                    <li>• Jangan gunakan informasi pribadi yang mudah ditebak</li>
                    <li>• Ubah password secara berkala untuk keamanan optimal</li>
                  </ul>
                </div>

                <Button onClick={handleUpdateAdminCredentials} className="flex items-center space-x-2">
                  <User className="h-4 w-4" />
                  <span>Perbarui Kredensial Admin</span>
                </Button>
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>
      </div>
    </div>
  );
};

export default AdminDashboard;
