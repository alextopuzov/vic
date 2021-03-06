# Copyright 2016-2017 VMware, Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#	http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License

*** Settings ***
Documentation  Test 1-02 - Docker Pull
Resource  ../../resources/Util.robot
Suite Setup  Install VIC Appliance To Test Server
Suite Teardown  Cleanup VIC Appliance On Test Server

*** Test Cases ***
Pull nginx
    Wait Until Keyword Succeeds  5x  15 seconds  Pull image  nginx

Pull busybox
    Wait Until Keyword Succeeds  5x  15 seconds  Pull image  busybox

Pull ubuntu
    Wait Until Keyword Succeeds  5x  15 seconds  Pull image  ubuntu

Pull non-default tag
    Wait Until Keyword Succeeds  5x  15 seconds  Pull image  nginx:alpine

Pull an image based on digest
    Wait Until Keyword Succeeds  5x  15 seconds  Pull image  nginx@sha256:7281cf7c854b0dfc7c68a6a4de9a785a973a14f1481bc028e2022bcd6a8d9f64

Pull an image with the full docker registry URL
    Wait Until Keyword Succeeds  5x  15 seconds  Pull image  registry.hub.docker.com/library/hello-world

Pull an image with all tags
    Wait Until Keyword Succeeds  5x  15 seconds  Pull image  --all-tags nginx

Pull non-existent image
    ${rc}  ${output}=  Run And Return Rc And Output  docker %{VCH-PARAMS} pull fakebadimage
    Log  ${output}
    Should Be Equal As Integers  ${rc}  1
    Should contain  ${output}  image library/fakebadimage not found

Pull image from non-existent repo
    ${rc}  ${output}=  Run And Return Rc And Output  docker %{VCH-PARAMS} pull fakebadrepo.com:9999/ubuntu
    Log  ${output}
    Should Be Equal As Integers  ${rc}  1
    Should Contain  ${output}  no such host

Pull image with a tag that doesn't exist
    ${rc}  ${output}=  Run And Return Rc And Output  docker %{VCH-PARAMS} pull busybox:faketag
    Log  ${output}
    Should Be Equal As Integers  ${rc}  1
    Should Contain  ${output}  Tag faketag not found in repository library/busybox

Pull image that already has been pulled
    Wait Until Keyword Succeeds  5x  15 seconds  Pull image  alpine
    Wait Until Keyword Succeeds  5x  15 seconds  Pull image  alpine

Pull the same image concurrently
    ${pids}=  Create List

    # Create 5 processes to pull the same image at once
    :FOR  ${idx}  IN RANGE  0  5
    \   ${pid}=  Start Process  docker %{VCH-PARAMS} pull redis  shell=True
    \   Append To List  ${pids}  ${pid}

    # Wait for them to finish and check their output
    :FOR  ${pid}  IN  @{pids}
    \   ${res}=  Wait For Process  ${pid}
    \   Log  ${res.stdout}
    \   Log  ${res.stderr}
    \   Should Be Equal As Integers  ${res.rc}  0
    \   Should Contain  ${res.stdout}  Downloaded newer image for library/redis:latest

Pull two images that share layers concurrently
     ${pid1}=  Start Process  docker %{VCH-PARAMS} pull golang:1.7  shell=True
     ${pid2}=  Start Process  docker %{VCH-PARAMS} pull golang:1.6  shell=True

    # Wait for them to finish and check their output
    ${res1}=  Wait For Process  ${pid1}
    ${res2}=  Wait For Process  ${pid2}
    Should Be Equal As Integers  ${res1.rc}  0
    Should Be Equal As Integers  ${res2.rc}  0
    Should Contain  ${res1.stdout}  Downloaded newer image for library/golang:1.7
    Should Contain  ${res2.stdout}  Downloaded newer image for library/golang:1.6

Re-pull a previously rmi'd image
    ${rc}  ${output}=  Run And Return Rc And Output  docker %{VCH-PARAMS} images |grep ubuntu
    ${words}=  Split String  ${output}
    ${id}=  Get From List  ${words}  2
    ${size}=  Get From List  ${words}  -2
    ${rc}  ${output}=  Run And Return Rc And Output  docker %{VCH-PARAMS} rmi ubuntu
    Wait Until Keyword Succeeds  5x  15 seconds  Pull image  ubuntu
    ${rc}  ${output}=  Run And Return Rc And Output  docker %{VCH-PARAMS} images |grep ubuntu
    ${words}=  Split String  ${output}
    ${newid}=  Get From List  ${words}  2
    ${newsize}=  Get From List  ${words}  -2
    Should Be Equal  ${id}  ${newid}
    Should Be Equal  ${size}  ${newsize}

Pull image by multiple tags
    Wait Until Keyword Succeeds  5x  15 seconds  Pull image  busybox:1.25.1
    Wait Until Keyword Succeeds  5x  15 seconds  Pull image  busybox:1.25
    ${rc}  ${output}=  Run And Return Rc And Output  docker %{VCH-PARAMS} images |grep -E busybox.*1.25
    Should Be Equal As Integers  ${rc}  0
    ${lines}=  Split To Lines  ${output}
    # one for 1.25.1 and one for 1.25
    Length Should Be  ${lines}  2
    ${line1}=  Get From List  ${lines}  0
    ${line2}=  Get From List  ${lines}  -1
    ${words1}=  Split String  ${line1}
    ${words2}=  Split String  ${line2}
    ${id1}=  Get From List  ${words1}  2
    ${id2}=  Get From List  ${words2}  2
    Should Be Equal  ${id1}  ${id2}
