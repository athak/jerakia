require 'securerandom'
require 'data_mapper'
# The server scope handler can store and retrieve scope data server side
#
class Jerakia::Scope
  module Server
    class Database
      DataMapper.setup(:scope, "sqlite://#{Jerakia.config[:databasedir]}/scope.db")
      Jerakia.log.debug("Server scope handler connected to sqlite://#{Jerakia.config[:databasedir]}/scope.db")

      class Resource
        include DataMapper::Resource


        def self.default_repository_name
          :scope
        end

        property :id, Serial, :key => true
        property :identifier, String, :index => true
        property :realm, String, :index => true
        property :uuid, String
        property :scope, Object
      end

      DataMapper.finalize
      DataMapper.auto_upgrade!
    end

    def create
      realm = request.scope_options['realm']
      identifier = request.scope_options['identifier']

      raise Jerakia::Error, "Must supply realm and identifier for server scope handler" unless realm and identifier
      resource = Jerakia::Scope::Server.find(realm, identifier)
      raise Jerakia::Error, "No scope data found for realm:#{realm} identifier:#{identifier}" if resource.nil?
      scope = resource.scope
      raise Jerakia::Error, "Scope did not return a hash for realm:#{realm} identifier:#{identifier}" unless scope.is_a?(Hash)
      @value = scope
    end

    class << self
      def find(realm, identifier)
        Database::Resource.first(:identifier => identifier, :realm => realm)
      end


      def store(realm, identifier, scope)
        uuid = SecureRandom.uuid
        entry = find(realm, identifier)
        if entry.nil?
          Database::Resource.create(:identifier => identifier, :realm => realm, :scope => scope, :uuid => uuid)
        else
          entry.update({:scope => scope, :uuid => uuid})
          entry.save
        end
        uuid
      end
    end
  end
end





