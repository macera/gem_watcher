worker_processes 2
working_directory "/var/opt/gem-watcher/rails_root"

listen File.expand_path("tmp/unicorn.sock", ENV['RAILS_ROOT'])
#listen 8079, tcp_nopush: true

pid File.expand_path("tmp/unicorn.pid", ENV['RAILS_ROOT'])

timeout 60

preload_app true

stdout_path File.expand_path("log/unicorn.stdout.log", ENV['RAILS_ROOT'])
stderr_path File.expand_path("log/unicorn.stderr.log", ENV['RAILS_ROOT'])

GC.respond_to?(:copy_on_write_friendly=) and GC.copy_on_write_friendly = true

before_fork do |server, worker|
  defined?(ActiveRecord::Base) and ActiveRecord::Base.connection.disconnect!

  old_pid = "#{server.config[:pid]}.oldbin"
    if old_pid != server.pid
      begin
        sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
        Process.kill(sig, File.read(old_pid).to_i)
      rescue Errno::ENOENT, Errno::ESRCH
      end
    end

    sleep 1
  end

after_fork do |server, worker|
  defined?(ActiveRecord::Base) and ActiveRecord::Base.establish_connection
end
