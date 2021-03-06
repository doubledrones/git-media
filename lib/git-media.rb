require 'trollop'
require 'fileutils'
require 'git-media/transport/local'
require 'git-media/transport/s3'
require 'git-media/transport/scp'

module GitMedia

  def self.get_media_buffer
    @@git_dir ||= `git rev-parse --git-dir`.chomp
    media_buffer = File.join(@@git_dir, 'media/objects')
    FileUtils.mkdir_p(media_buffer) if !File.exist?(media_buffer)
    return media_buffer
  end

  def self.media_path(sha)
    buf = self.get_media_buffer
    File.join(buf, sha)    
  end
  
  # TODO: select the proper transports based on settings
  def self.get_push_transport
    self.get_transport
  end

  def self.get_transport
    case `git config git-media.transport`.chomp
    when ""
      raise "git-media.transport not set"
    when "scp"
      user = `git config git-media.scpuser`.chomp
      host = `git config git-media.scphost`.chomp
      path = `git config git-media.scppath`.chomp
      if user === ""
	raise "git-media.scpuser not set for scp transport"
      end
      if host === ""
	raise "git-media.scphost not set for scp transport"
      end
      if path === ""
	raise "git-media.scppath not set for scp transport"
      end
      GitMedia::Transport::Scp.new(user, host, path)

    when "local"
      path = `git config git-media.localpath`.chomp
      if path === ""
	raise "git-media.localpath not set for local transport"
      end
      GitMedia::Transport::Local.new(path)
    when "s3"
      bucket = `git config git-media.s3bucket`.chomp
      key = `git config git-media.s3key`.chomp
      secret = `git config git-media.s3secret`.chomp
      if bucket === ""
	raise "git-media.s3bucket not set for s3 transport"
      end
      if key === ""
	raise "git-media.s3key not set for s3 transport"
      end
      if secret === ""
	raise "git-media.s3secret not set for s3 transport"
      end
      GitMedia::Transport::S3.new(bucket, key, secret)
    end
  end

  def self.get_pull_transport
    self.get_transport
  end

  module Application
    def self.run!
      
      cmd = ARGV.shift # get the subcommand
      cmd_opts = case cmd
        when "filter-clean" # parse delete options
          require 'git-media/filter-clean'
          GitMedia::FilterClean.run!
        when "filter-smudge"
          require 'git-media/filter-smudge'
          GitMedia::FilterSmudge.run!
        when "clear" # parse delete options
          require 'git-media/clear'
          GitMedia::Clear.run!
        when "sync"
          require 'git-media/sync'
          GitMedia::Sync.run!
        when 'status'
          require 'git-media/status'
          Trollop::options do
            opt :force, "Force status"
          end
          GitMedia::Status.run!
        else
          raise "unknown media subcommand #{cmd.inspect}"
        end
      
    end
  end
end
