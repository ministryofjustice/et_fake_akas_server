require 'base64'
require 'openssl'
module EtFakeAcasServer
  class NoMatchXmlBuilder
    def initialize(form, rsa_et_certificate_path:)
      self.form = form
      self.rsa_et_certificate = OpenSSL::X509::Certificate.new File.read(rsa_et_certificate_path)
    end

    def key
      @key ||= '12345678901234567890123456789012'
    end

    def iv
      @iv ||= '12345678901234567890123456789012'
    end

    def builder
      Nokogiri::XML::Builder.new do |xml|
        namespaces = {
            'xmlns:s' => 'http://schemas.xmlsoap.org/soap/envelope',
            'xmlns:u' => 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd'
        }
        xml['s'].Envelope(namespaces) do
          xml['s'].Header do
            xml.ActivityId("e67a4d86-e096-4a35-aa3a-2b3a8ffaaa54", 'CorrelationId': '03973d23-3c39-4359-aa69-4d37b922fb60', xmlns: 'http://schemas.microsoft.com/2004/09/ServiceModel/Diagnostics')
            xml['o'].Security('s:mustUnderstand': '1', 'xmlns:o': 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd') do
              xml['u'].Timestamp('u:Id': '_0') do
                xml['u'].Created '2014-03-03T10:15.01.251Z'
                xml['u'].Expires '2014-03-03T10:20:01.251Z'
              end
            end
          end
          xml['s'].Body do
            xml.GetECCertificateResponse(xmlns: 'https://ec.acas.org.uk/lookup/') do
              xml.GetECCertificateResult('xmlns:a': 'http://schemas.datacontract.org/2004/07/Acas.CertificateLookup.EcLookupService', 'xmlns:i': 'http://www.w3.org/2001/XMLSchema-instance') do
                xml['a'].CurrentDateTime Base64.encode64(aes_encrypt(Time.now.strftime('%d/%m/%Y %H:%M:%S')))
                xml['a'].IV Base64.encode64(rsa_encrypt(Base64.encode64(iv)))
                xml['a'].Key Base64.encode64(rsa_encrypt(Base64.encode64(key)))
                xml['a'].Message Base64.encode64(aes_encrypt('Certificate not found'))
                xml['a'].ResponseCode Base64.encode64(aes_encrypt('200'))
                xml['a'].ServiceVersion Base64.encode64(aes_encrypt('1.0'))
              end
            end
          end
        end
      end

    end

    private

    attr_accessor :rsa_et_certificate, :form

    def aes_encrypt(value)
      encrypt_cipher = build_encrypt_cipher
      encrypt_cipher.encrypt(value)
    end

    def build_encrypt_cipher
      Mcrypt.new(:rijndael_256, :cbc, key, iv, :pkcs7)
    end

    def rsa_encrypt(value)
      rsa_et_certificate.public_key.public_encrypt(value, OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING)
    end
  end
end
