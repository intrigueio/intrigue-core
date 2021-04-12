module Intrigue
module Task
class Gitrob < BaseTask

  def self.metadata
    {
      :name => "gitrob",
      :pretty_name => "Gitrob",
      :authors => ["michenriksen", "jcran"],
      :description => "Uses the excellent Gitrob by Michael Henriksen to search a given Github Account for committed secrets",
      :type => "discovery",
      :references => ["https://github.com/michenriksen/gitrob"],
      :passive => true,
      :allowed_types => ["GithubAccount"],
      :example_entities => [{"type" => "GithubAccount", "details" => {"name" => "intrigueio"}}],
      :allowed_options => [],
      :created_types => ["GithubRepository"]
    }
  end

  def run
    super

    github_account = _get_entity_name
    token = _get_task_config "gitrob_access_token"

    # output file
    temp_file = "#{Dir::tmpdir}/gitrob_#{rand(1000000000000)}.json"

    # task assumes gitrob is in our path and properly configured
    _log "Starting Gitrob on #{github_account}, saving to #{temp_file}!"
    command_string = "gitrob -github-access-token #{token} -save #{temp_file} -exit-on-finish -no-expand-orgs -commit-depth 10 --threads 20 -in-mem-clone #{github_account}"
    # gitrob tends to hang so we set a timeout of 10 minutes (600 seconds)
    # the gitrob fork we use requires two files in the current working directory, hence setting working dir to ~/bin/data/gitrob
    _unsafe_system command_string, 3600, "#{Dir.home}/bin/data/gitrob"
    _log "Gitrob finished on #{github_account}!"

    # parse output
    begin
      output = JSON.parse(File.open(temp_file,"r").read)
    rescue Errno::ENOENT => e
      _log_error "No such file: #{temp_file}"
    rescue JSON::ParserError => e
      _log_error "Unable to parse: #{temp_file}"
    end

    # sanity check
    unless output
      _log_error "No output, failing"
      return
    end

    _log "Gitrob Version: #{output["Version"]}"
    _log "Gitrob Stats: #{output["Stats"]}"

    # create accounts from the targets
    #if output["Targets"]
    #  output["Targets"].each do |t|
    #    _create_entity "GithubAccount", {
    #      "name" => "#{t["Login"]}",
    #      "uri" => "#{t["URL"]}",
    #      "account_type" => "#{t["Type"]}",
    #      "raw" => t
    #    }
    #  end
    #else
    #  _log "No targets!"
    #end

    # create respositories
    repo_entities = []
    if output["Repositories"]
      output["Repositories"].each do |r|
        repo_entities << _create_entity "GithubRepository", {
          "name" => "#{r["FullName"]}",
          "uri" => "#{r["URL"]}",
          "description" => "#{r["description"]}",
          "raw" => r
        }
      end
    else
      _log "No repositories!"
    end

    # create findings
    suspicious_commits = []
    if output["Findings"]
      finding_hash = {}
      output["Findings"].each do |f|

        # skip if credentials or password is used in the fileurl
        next if (f["Description"] == "Contains word: credential" && f["FilePath"] =~ /credential\.\w{2,5}/i )
        next if (f["Description"] == "Contains word: password" && f["FilePath"] =~ /password\.\w{2,5}/i )
        next if (f["Description"] == "Contains word: password" && f["FilePath"] =~ /password_reset_done\.\w{2,5}/i )
        next if (f["Description"] == "Contains word: password" && f["FilePath"] =~ /password_reset_confirm\.\w{2,5}/i )
        next if (f["Description"] == "Contains word: password" && f["FilePath"] =~ /password_reset_complete\.\w{2,5}/i )
        next if (f["Description"] == "Contains word: password" && f["FilePath"] =~ /password_reset_form\.\w{2,5}/i )
        next if (f["Description"] == "Contains word: password" && f["FilePath"] =~ /password_reset_email\.\w{2,5}/i )

        # add it to our output
        suspicious_commits << f
      end

    else
      _log "No findings!"
    end

    repo

    suspicious_commits.each do |sc|
      repo_name = "#{sc["RepositoryUrl"]}".gsub("https://github.com/")
      e = repo_entities.find{|x| x.name == repo_name }
      _create_linked_issue("suspicious_commit", {
        source: sc["Id"],
        proof: {
          sig: sc["FileSignatureDescription"],
          commit: sc["CommitUrl"]
        }
      }.merge(sc), e )
    end

    # clean up
    begin
      File.delete(temp_file)
    rescue Errno::EPERM
      _log_error "Unable to delete file"
    end

  end # end run

end
end
end
