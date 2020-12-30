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
    command_string = "gitrob -github-access-token #{token} -save #{temp_file} -exit-on-finish -no-expand-orgs -commit-depth 20 --threads 20 -in-mem-clone #{github_account}"
    # gitrob tends to hang so we set a timeout of 5 minutes (300 seconds)
    # the gitrob fork we use requires two files in the current working directory, hence setting working dir to ~/bin/data/gitrob
    _unsafe_system_timed command_string, 300, "#{Dir.home}/bin/data/gitrob"
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
    if output["Repositories"]
      output["Repositories"].each do |r|
        _create_entity "GithubRepository", {
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
    if output["Findings"]
      finding_hash = {}
      output["Findings"].each do |f|

        # skip if credentials or password is used in the fileurl
        next if (f["Description"] == "Contains word: credential" && f["FilePath"] =~ /credential.html/i )
        next if (f["Description"] == "Contains word: password" && f["FilePath"] =~ /password.html/i )

        ############################################
        ###      New Issue                      ###
        ###########################################
        _create_linked_issue("suspicious_commit", {
          name: "Suspicious #{f["Action"]} Commit Found In Github Repository",
          detailed_description:  "A suspicious commit was found in a public Github repository.\n" +
                        "Repository URL: #{f['RepositoryUrl']}\n" +
                        "Commit Author: #{f["CommitAuthor"]}\n" +
                        "Commit Message #{f["CommitMessage"]}\n" +
                        "Details: #{f["Action"]} #{f["Description"]} at #{f["FileUrl"]}\n\n#{f["Comment"]}",
          details: f.merge({uri: "#{f["CommitUrl"]}"})
        })
      end

    else
      _log "No findings!"
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
