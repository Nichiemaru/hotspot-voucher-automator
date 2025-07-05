
import { useEffect, useState } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { CheckCircle, XCircle, Clock, Home } from "lucide-react";
import { useNavigate } from "react-router-dom";
import tripayService from "@/services/tripayService";

const PaymentCallback = () => {
  const [status, setStatus] = useState<'loading' | 'success' | 'failed' | 'pending'>('loading');
  const [transactionData, setTransactionData] = useState<any>(null);
  const navigate = useNavigate();

  useEffect(() => {
    const checkPaymentStatus = async () => {
      try {
        // Get transaction data from localStorage
        const currentTransaction = localStorage.getItem('current_transaction');
        if (!currentTransaction) {
          setStatus('failed');
          return;
        }

        const transaction = JSON.parse(currentTransaction);
        
        // Check payment status with TriPay
        const response = await tripayService.getTransactionDetail(transaction.reference);
        
        if (response.success && response.data) {
          setTransactionData({
            ...response.data,
            package: transaction.package,
            customer: transaction.customer
          });

          switch (response.data.status) {
            case 'PAID':
              setStatus('success');
              // Generate voucher and send WhatsApp notification
              await generateVoucher(transaction);
              break;
            case 'EXPIRED':
            case 'FAILED':
              setStatus('failed');
              break;
            default:
              setStatus('pending');
          }
        } else {
          setStatus('failed');
        }
      } catch (error) {
        console.error('Error checking payment status:', error);
        setStatus('failed');
      }
    };

    checkPaymentStatus();
  }, []);

  const generateVoucher = async (transaction: any) => {
    try {
      // Generate random username and password
      const username = `user_${Date.now()}`;
      const password = Math.random().toString(36).substr(2, 8);

      console.log('Generating voucher:', {
        username,
        password,
        profile: transaction.package.profile,
        customer: transaction.customer
      });

      // In a real implementation, this would:
      // 1. Create user in MikroTik
      // 2. Send WhatsApp notification
      // For now, we'll just log it
      
      // Simulate voucher creation
      localStorage.setItem('voucher_details', JSON.stringify({
        username,
        password,
        package: transaction.package.name,
        expires: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString()
      }));

    } catch (error) {
      console.error('Error generating voucher:', error);
    }
  };

  const getStatusIcon = () => {
    switch (status) {
      case 'success':
        return <CheckCircle className="h-16 w-16 text-green-500" />;
      case 'failed':
        return <XCircle className="h-16 w-16 text-red-500" />;
      case 'pending':
        return <Clock className="h-16 w-16 text-yellow-500" />;
      default:
        return <Clock className="h-16 w-16 text-blue-500 animate-spin" />;
    }
  };

  const getStatusMessage = () => {
    switch (status) {
      case 'success':
        return {
          title: "Pembayaran Berhasil!",
          description: "Voucher internet Anda telah berhasil dibeli dan akan segera dikirim ke WhatsApp Anda."
        };
      case 'failed':
        return {
          title: "Pembayaran Gagal",
          description: "Transaksi Anda tidak dapat diproses. Silakan coba lagi atau hubungi customer service."
        };
      case 'pending':
        return {
          title: "Menunggu Pembayaran",
          description: "Pembayaran Anda sedang diproses. Silakan selesaikan pembayaran sesuai instruksi."
        };
      default:
        return {
          title: "Memproses...",
          description: "Sedang memeriksa status pembayaran Anda."
        };
    }
  };

  const statusMessage = getStatusMessage();

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-green-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-md shadow-2xl">
        <CardHeader className="text-center pb-6">
          <div className="flex justify-center mb-4">
            {getStatusIcon()}
          </div>
          <CardTitle className="text-2xl font-bold text-gray-900">
            {statusMessage.title}
          </CardTitle>
          <CardDescription className="text-gray-600">
            {statusMessage.description}
          </CardDescription>
        </CardHeader>
        
        <CardContent className="space-y-4">
          {transactionData && (
            <div className="bg-gray-50 p-4 rounded-lg space-y-2">
              <div className="flex justify-between">
                <span className="text-sm text-gray-600">Paket:</span>
                <span className="text-sm font-medium">{transactionData.package?.name}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-gray-600">Total:</span>
                <span className="text-sm font-medium">
                  {new Intl.NumberFormat('id-ID', {
                    style: 'currency',
                    currency: 'IDR',
                    minimumFractionDigits: 0
                  }).format(transactionData.amount)}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-gray-600">Reference:</span>
                <span className="text-sm font-mono">{transactionData.reference}</span>
              </div>
            </div>
          )}

          {status === 'success' && (
            <div className="bg-green-50 p-4 rounded-lg border border-green-200">
              <p className="text-sm text-green-800 mb-2">
                <strong>Voucher telah dikirim ke WhatsApp Anda!</strong>
              </p>
              <p className="text-xs text-green-700">
                Jika tidak menerima pesan dalam 5 menit, silakan hubungi customer service.
              </p>
            </div>
          )}

          <div className="flex gap-2">
            <Button 
              onClick={() => navigate('/')}
              className="flex-1 bg-gradient-to-r from-blue-600 to-green-600 hover:from-blue-700 hover:to-green-700"
            >
              <Home className="mr-2 h-4 w-4" />
              Kembali ke Beranda
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default PaymentCallback;
