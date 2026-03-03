/*
 * DBeaver - Universal Database Manager
 * Copyright (C) 2010-2026 DBeaver Corp and others
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.jkiss.dbeaver.ext.scratchbird.model;

import org.jkiss.code.NotNull;
import org.jkiss.utils.CommonUtils;

import java.util.ArrayList;
import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

final class ScratchBirdSchemaTreeBuilder {

    private ScratchBirdSchemaTreeBuilder() {
    }

    @NotNull
    static List<Node> build(@NotNull Collection<String> schemaPaths) {
        Map<String, Node> nodesByPath = new LinkedHashMap<>();
        List<Node> roots = new ArrayList<>();

        for (String fullPath : schemaPaths) {
            if (CommonUtils.isEmpty(fullPath)) {
                continue;
            }

            Node parent = null;
            StringBuilder pathBuilder = new StringBuilder();
            for (String segment : splitPath(fullPath)) {
                if (pathBuilder.length() > 0) {
                    pathBuilder.append('.');
                }
                pathBuilder.append(segment);
                String currentPath = pathBuilder.toString();

                Node node = nodesByPath.get(currentPath);
                if (node == null) {
                    node = new Node(segment, currentPath);
                    nodesByPath.put(currentPath, node);
                    if (parent == null) {
                        roots.add(node);
                    } else {
                        parent.addChild(node);
                    }
                }

                parent = node;
            }

            if (parent != null) {
                parent.setTerminal(true);
            }
        }

        return roots;
    }

    @NotNull
    private static List<String> splitPath(@NotNull String fullPath) {
        List<String> segments = new ArrayList<>();
        for (String segment : fullPath.split("\\.")) {
            if (!segment.isEmpty()) {
                segments.add(segment);
            }
        }
        return segments;
    }

    static final class Node {
        @NotNull
        private final String name;
        @NotNull
        private final String fullPath;
        @NotNull
        private final Map<String, Node> children = new LinkedHashMap<>();
        private boolean terminal;

        private Node(@NotNull String name, @NotNull String fullPath) {
            this.name = name;
            this.fullPath = fullPath;
        }

        @NotNull
        String getName() {
            return name;
        }

        @NotNull
        String getFullPath() {
            return fullPath;
        }

        @NotNull
        Collection<Node> getChildren() {
            return children.values();
        }

        boolean isTerminal() {
            return terminal;
        }

        void setTerminal(boolean terminal) {
            this.terminal = terminal;
        }

        void addChild(@NotNull Node child) {
            children.putIfAbsent(child.getName(), child);
        }
    }
}
