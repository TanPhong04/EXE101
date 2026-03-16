import React, { useState, useRef } from 'react';
import { Shield, Upload, CheckCircle2, X, Image as ImageIcon, FileText, Camera } from 'lucide-react';
import Modal from '../ui/Modal';
import Button from '../ui/Button';
import { useAuth } from '../../context/AuthContext';

interface TravelerVerificationModalProps {
  isOpen: boolean;
  onClose: () => void;
  status?: 'verified' | 'pending' | 'unverified';
}

const TravelerVerificationModal: React.FC<TravelerVerificationModalProps> = ({ isOpen, onClose, status = 'unverified' }) => {
  const { updateUser } = useAuth();
  const [step, setStep] = useState<'upload' | 'success'>(status === 'pending' ? 'success' : 'upload');
  const [avatar, setAvatar] = useState<File | null>(null);
  const [passport, setPassport] = useState<File | null>(null);
  const [loading, setLoading] = useState(false);
  
  const avatarInputRef = useRef<HTMLInputElement>(null);
  const passportInputRef = useRef<HTMLInputElement>(null);

  const handleUpload = async () => {
    if (!avatar || !passport) return;
    setLoading(true);
    try {
      // Simulate API call to upload and update status
      await new Promise(resolve => setTimeout(resolve, 1500));
      await updateUser({ verificationStatus: 'pending' });
      setStep('success');
    } catch (error) {
      console.error("Verification failed:", error);
    } finally {
      setLoading(false);
    }
  };

  if (status === 'pending') {
      return (
        <Modal isOpen={isOpen} onClose={onClose}>
            <div className="p-10 text-center space-y-8 max-w-md mx-auto">
                <div className="w-24 h-24 bg-primary/10 rounded-[32px] flex items-center justify-center text-primary mx-auto animate-pulse">
                    <Shield size={48} strokeWidth={2.5} />
                </div>
                <div className="space-y-4">
                    <h2 className="text-3xl font-black text-secondary tracking-tight">Identity Pending</h2>
                    <p className="text-secondary/60 font-medium leading-relaxed italic">
                        Your verification documents are currently being processed by our specialized security team.
                    </p>
                </div>
                <div className="p-6 bg-surface-dark rounded-3xl border border-gray-100 flex items-center gap-4 text-left">
                    <div className="w-10 h-10 bg-white rounded-xl shadow-sm flex items-center justify-center text-primary shrink-0">
                        <Camera size={18} />
                    </div>
                    <p className="text-[10px] font-black text-secondary/40 uppercase tracking-widest leading-relaxed">
                        Typical approval time is <span className="text-primary">2 - 6 hours</span>. We will notify you via email once approved.
                    </p>
                </div>
                <Button onClick={onClose} className="w-full py-5 rounded-2xl">Understood</Button>
            </div>
        </Modal>
      );
  }

  return (
    <Modal isOpen={isOpen} onClose={onClose}>
      <div className="p-8 md:p-12 space-y-12 max-w-xl mx-auto">
        {step === 'upload' ? (
          <>
            <div className="space-y-4 text-center">
              <div className="w-20 h-20 bg-primary/10 rounded-[32px] flex items-center justify-center text-primary mx-auto mb-6">
                <Shield size={40} strokeWidth={2.5} />
              </div>
              <h2 className="text-4xl font-black text-secondary tracking-tight leading-none italic">
                Identity <span className="text-primary not-italic">Verification</span>
              </h2>
              <p className="text-secondary/40 font-bold max-w-md mx-auto leading-relaxed">
                To ensure community safety, travelers must verify their identity before connecting with Local Buddies.
              </p>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {/* Avatar Upload */}
              <div 
                onClick={() => avatarInputRef.current?.click()}
                className={`group relative h-48 rounded-[40px] border-4 border-dashed transition-all flex flex-col items-center justify-center cursor-pointer ${avatar ? 'border-accent-green bg-accent-green/5' : 'border-gray-100 hover:border-primary/20 bg-surface-dark hover:bg-primary/5'}`}
              >
                <input 
                  type="file" 
                  ref={avatarInputRef} 
                  hidden 
                  accept="image/*" 
                  onChange={(e) => setAvatar(e.target.files?.[0] || null)}
                />
                {avatar ? (
                  <div className="text-center space-y-2">
                    <CheckCircle2 className="text-accent-green mx-auto" size={32} />
                    <p className="text-[9px] font-black text-accent-green uppercase tracking-widest">Avatar Selected</p>
                  </div>
                ) : (
                  <div className="text-center space-y-3">
                    <div className="w-12 h-12 bg-white rounded-2xl flex items-center justify-center text-secondary/20 group-hover:text-primary transition-colors shadow-sm">
                      <Camera size={24} />
                    </div>
                    <p className="text-[10px] font-black text-secondary/20 uppercase tracking-widest">Step 1: Face Photo</p>
                  </div>
                )}
              </div>

              {/* Passport Upload */}
              <div 
                onClick={() => passportInputRef.current?.click()}
                className={`group relative h-48 rounded-[40px] border-4 border-dashed transition-all flex flex-col items-center justify-center cursor-pointer ${passport ? 'border-accent-green bg-accent-green/5' : 'border-gray-100 hover:border-primary/20 bg-surface-dark hover:bg-primary/5'}`}
              >
                <input 
                  type="file" 
                  ref={passportInputRef} 
                  hidden 
                  accept="image/*" 
                  onChange={(e) => setPassport(e.target.files?.[0] || null)}
                />
                {passport ? (
                  <div className="text-center space-y-2">
                    <CheckCircle2 className="text-accent-green mx-auto" size={32} />
                    <p className="text-[9px] font-black text-accent-green uppercase tracking-widest">Passport Selected</p>
                  </div>
                ) : (
                  <div className="text-center space-y-3">
                    <div className="w-12 h-12 bg-white rounded-2xl flex items-center justify-center text-secondary/20 group-hover:text-primary transition-colors shadow-sm">
                      <FileText size={24} />
                    </div>
                    <p className="text-[10px] font-black text-secondary/20 uppercase tracking-widest">Step 2: Passport/ID</p>
                  </div>
                )}
              </div>
            </div>

            <div className="space-y-4">
              <Button 
                onClick={handleUpload}
                disabled={loading || !avatar || !passport}
                className="w-full py-6 rounded-2xl text-[10px] font-black uppercase tracking-widest shadow-primary-glow"
              >
                {loading ? 'Processing Security Layers...' : 'Submit for Verification'}
              </Button>
              <button 
                onClick={onClose}
                className="w-full text-[10px] font-black text-secondary/30 uppercase tracking-[0.3em] hover:text-secondary/60 transition-colors"
              >
                Cancel Process
              </button>
            </div>
          </>
        ) : (
          <div className="text-center space-y-8 animate-in zoom-in-95 duration-500">
            <div className="w-24 h-24 bg-accent-green/10 rounded-[32px] flex items-center justify-center text-accent-green mx-auto">
              <CheckCircle2 size={48} strokeWidth={2.5} />
            </div>
            <div className="space-y-4">
              <h2 className="text-3xl font-black text-secondary tracking-tight">Identity Submitted!</h2>
              <p className="text-secondary/60 font-medium leading-relaxed italic">
                Thank you for contributing to a safer community. Our team is now reviewing your documents.
              </p>
            </div>
            <div className="p-6 bg-surface-dark rounded-3xl border border-gray-100 flex items-center gap-4 text-left">
              <div className="w-10 h-10 bg-white rounded-xl shadow-sm flex items-center justify-center text-primary shrink-0">
                <Shield size={18} />
              </div>
              <p className="text-[10px] font-black text-secondary/40 uppercase tracking-widest leading-relaxed">
                Approval usually takes <span className="text-primary">2 - 6 hours</span>. we will notify you shortly.
              </p>
            </div>
            <Button onClick={onClose} className="w-full py-5 rounded-2xl">Back to Community</Button>
          </div>
        )}
      </div>
    </Modal>
  );
};

export default TravelerVerificationModal;
