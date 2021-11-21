# encoding: ascii-8bit

require 'cosmos'
require 'cosmos/interfaces/tcpip_client_interface'
require 'json'
require_relative 'kasa_protocol'

module Cosmos
  class KasaInterface < TcpipClientInterface
    def initialize (hostname, port, polling_period_seconds = 30, write_timeout = 10.0, read_timeout = nil)
      super(hostname, port, port, write_timeout, read_timeout, 'LENGTH', 0, 32, 4)
      add_protocol(KasaProtocol, [], :READ_WRITE)
      @status_packet = nil
      @polling_period_seconds = polling_period_seconds.to_i
      @polling_thread = nil
      @polling_thread_run = true
      @polling_thread_sleeper = nil
    end

    def connect
      super()

      if @polling_period_seconds > 0
        @polling_thread_run = true
        @polling_thread_sleeper = Sleeper.new
        @polling_thread = Thread.new do 
          while @polling_thread_run
            send_info_command()
            break if @polling_thread_sleeper.sleep(@polling_period_seconds)
          end
        rescue => err
          Logger.instance.error("Polling thread unexpectedly died : #{@name}")
          raise err
        end
      end
    end

    def disconnect
      if @polling_thread
        @polling_thread_run = false
        @polling_thread_sleeper.cancel
        @polling_thread.join
        @polling_thread = nil
        @polling_thread_sleeper = nil
      end
      super()
    end

    def write(packet)
      result = super(packet)
      # Follow every non-INFO command with an INFO command
      send_info_command() if packet.packet_name != 'INFO'
      return result
    end

    def read
      if @status_packet
        packet = @status_packet
        @status_packet = nil
        return packet
      end
      packet = super()

      # Info Command Results Format
      # {
      #   "system":
      #   {
      #     "get_sysinfo":
      #     {
      #       "sw_ver":"1.0.3 Build 201015 Rel.142523",
      #       "hw_ver":"5.0","model":"HS103(US)",
      #       "deviceId":"8006E861C909AAF4BABED171339873F91E67E71C",
      #       "oemId":"211C91F3C6FA93568D818524FE170CEC",
      #       "hwId":"B25CBC5351DD892EA69AB42199F59E41",
      #       "rssi":-51,
      #       "latitude_i":400299,
      #       "longitude_i":-1050636,
      #       "alias":"Plug1",
      #       "status":"new",
      #       "mic_type":"IOT.SMARTPLUGSWITCH",
      #       "feature":"TIM",
      #       "mac":"00:31:92:43:F4:35",
      #       "updating":0,
      #       "led_off":1,
      #       "relay_state":0,
      #       "on_time":0,
      #       "icon_hash":"",
      #       "dev_name":"Smart Wi-Fi Plug Mini",
      #       "active_mode":"none",
      #       "next_action":{"type":-1},
      #       "err_code":0
      #     }
      #   }
      # }

      if packet
        json_hash = JSON.parse(packet.buffer(false))
        system = json_hash['system']
        if system
          get_sysinfo = system['get_sysinfo']
          if get_sysinfo
            @status_packet = System.telemetry.packet(@target_names[0], 'STATUS')
            @status_packet.write('PACKET_ID', 1)
            relay = get_sysinfo['relay_state']
            @status_packet.write('RELAY', relay)
            led_off = get_sysinfo['led_off']
            if led_off == 0
              led = 1
            else
              led = 0
            end
            @status_packet.write('LED', led)
            @status_packet.received_time = nil
          end
        end
      end

      return packet
    end

    def send_info_command
      info_command = System.commands.packet(@target_names[0], 'INFO').dup
      info_command.restore_defaults
      write(info_command)
    end
  end
end
