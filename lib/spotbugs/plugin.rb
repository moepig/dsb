module Danger
  class DangerSpotbugs < Plugin
    require_relative './bug_issue'

    # @return [String]
    attr_writer :maven_task

    # @return [String]
    attr_writer :report_file

    # @return [String]
    attr_accessor :maven_project

    # @return [Bool]
    attr_writer :skip_maven_task


    MAVEN_NOT_FOUND = "Could not find `maven`"
    REPORT_FILE_NOT_FOUND = "Spotbugs report not found"

    # @return [void]
    def report(inline_mode = true)
      unless skip_maven_task
        return fail(MAVEN_NOT_FOUND) unless maven_exists?
        exec_maven_task
      end
      return fail(REPORT_FILE_NOT_FOUND) unless report_file_exist?

      if inline_mode
        send_inline_comment
      else
          task = maven_task
          file = report_file
          @maven_task = task
          @report_file = "target/" + file

          execute_reporting(inline_mode)
      end
    end

    # @return [void]
    def execute_reporting(inline_mode)
        exec_maven_task
        return fail(REPORT_FILE_NOT_FOUND) unless report_file_exist?

        if inline_mode
          send_inline_comment
        else
          # TODO not implemented
        end
    end

    # @return [String]
    def maven_task
      @maven_task  ||= 'spotbugs:spotbugs'
    end

    # @return [String]
    def report_file
      @report_file ||= 'target/spotbugsXml.xml'
    end

    # @return [String]
    def maven_project
      return @maven_project ||= ''
    end
    private

    # @return [Array[String]]
    def target_files
      @target_files ||= (git.modified_files - git.deleted_files) + git.added_files
    end

    # @return [void]
    def exec_maven_task
      if maven_project != ''
        "export DANGER_TMP=$PWD"
        "cd #{gradle_project}"
      end
      system "maven #{maven_task}"
      if maven_project != ''
        "cd DANGER_TMP"
      end
    end

    # @return [Bool]
    def maven_exists?
      `which maven`.strip.empty? == false
    end

    # @return [Bool]
    def report_file_exist?
      File.exists?("#{maven_project}#{report_file}")
    end

    # @return [Oga::XML::Document]
    def spotbugs_report
      require 'oga'
      @spotbugs_report ||= Oga.parse_xml(File.open("#{maven_project}#{report_file}"))
    end

    # @return [Array[BugIssue]]
    def bug_issues
      @bug_issues ||= spotbugs_report.xpath("//BugInstance").map do |buginfo|
        BugIssue.new(maven_task, buginfo)
      end
    end

    # @return [void]
    def send_inline_comment
      bug_issues.each do |issue|
        filename = "#{maven_project}#{issue.absolute_path}"
        next unless target_files.include? filename
        send(issue.type, issue.description, file: filename, line: issue.line)
      end
    end
  end
end
