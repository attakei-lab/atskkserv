============
インストール
============

.. todo:: リポジトリのURLを調整後に詳細を記述する。

.. important::

   「個人的な利用」にウェイトを掛けている関係で、細かいインストール手法を用意していません。

複数の手段でインストールができます。

aqua経由でのインストール
========================

このプロダクトは、aqua用のカスタムレジストリを同じリポジトリ上で公開しています。
aqua用のファイルを編集することで、 ``aqua generate`` によるインストールが出来ます。

.. code-block:: yaml
   :caption: aqua-policy.yaml

   ---
   # yaml-language-server: $schema=https://raw.githubusercontent.com/aquaproj/aqua/main/json-schema/policy.json
   # aqua Policy
   # https://aquaproj.github.io/
   registries:
     - type: standard
       ref: semver(">= 3.0.0")
     # このレジストリを追加する
     - name: attakei/atskkserv
       type: github_content
       repo_owner: attakei
       repo_name: atskkserv
       path: aqua/registry.yaml
   packages:
     - registry: standard
     # このレジストリを追加する
     - registry: attakei/atskkserv

``aqua-policy.yaml`` 上記のように編集して、 [#]_
``aqua g -i attakei/atskkserv`` と実行することでインストール対象に加えることができます。

.. [#] あるいは、このファイルをそのまま ``aqua-policy.yamlj`` として保存します。

GitHub Releasesからのダウンロード
=================================

`GitHub Releases <https://github.com/attakei/atskkserv/releases>`_ 上には、
各OS毎にビルドした実行ファイルが公開されています。
必要なバージョンを選択してダウンロードしてください。

現在のビルドでは、追加で必要なファイルは無いため、ダウンロードしたものをそのまま使用できます。

